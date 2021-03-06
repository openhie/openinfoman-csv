module namespace page = 'http://basex.org/modules/web-page';

(:Import other namespaces.  :)
import module namespace csd_webui =  "https://github.com/openhie/openinfoman/csd_webui";
import module namespace csr_proc = "https://github.com/openhie/openinfoman/csr_proc";
import module namespace csd_dm = "https://github.com/openhie/openinfoman/csd_dm";


declare namespace csd = "urn:ihe:iti:csd:2013";


declare function page:is_csv($search_name) {
  let $function := csr_proc:get_function_definition($search_name)
  let $ext := $function//csd:extension[  @urn='urn:openhie.org:openinfoman:adapter' and @type='csv']
  return (count($ext) > 0) 
};




declare
  %rest:path("/CSD/csr/{$doc_name}/careServicesRequest/{$search_name}/adapter/csv")
  %output:method("xhtml")
  function page:show_endpoints($search_name,$doc_name) 
{  
    if (not(page:is_csv($search_name)) ) 
      then ('Not a CSV Compatible stored function'    )
    else 
      let $contents := 
      <div>
        <h2>CSV Export for {$doc_name}</h2>
        { 
	  let $url := csd_webui:generateURL(("CSD/csr/" , $doc_name , "/careServicesRequest/",$search_name, "/adapter/csv/get"))
	  return <p>Get the  <a href="{$url}">CSV Export</a></p>
	}
      </div>
      return csd_webui:wrapper($contents)
};


 
declare
  %rest:path("/CSD/csr/{$doc_name}/careServicesRequest/{$search_name}/adapter/csv/get")
  function page:get($search_name,$doc_name) 
{
  if (not(page:is_csv($search_name)) ) 
    then ('Not a CSV Compatible stored function'    )
  else 
    let $doc :=  csd_dm:open_document($doc_name)
    let $function := csr_proc:get_function_definition($search_name)

    let $careServicesRequest := 
      <csd:careServicesRequest urn="{$search_name}" resource="{$doc_name}" base_url="{csd_webui:generateURL()}">
         <csd:requestParams/>
     </csd:careServicesRequest> 
    let $csv := csr_proc:process_CSR_stored_results( $doc,$careServicesRequest) 
    let $output := $function/@content-type
    let $mime := 
      if (exists($output))
      then string($output)
      else "text/html"
    return 
    ( 
      <rest:response>
	<http:response status="200" >
          <http:header name='Content-Type' value="{$mime}"/>
	  <http:header name='Content-Disposition' value="attachment; filename='{$doc_name}.csv'"/>
	</http:response>
      </rest:response>
      ,$csv
    )


};


