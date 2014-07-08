(:~
: This is the Care Services Discovery stored query registry
: @version 1.0
: @see https://github.com/openhie/openinfoman
:
:)
module namespace oi_csv = "https://github.com/openhie/openinfoman/adapter/csv";
import module namespace csd_webconf =  "https://github.com/openhie/openinfoman/csd_webconf";
import module namespace csr_proc = "https://github.com/openhie/openinfoman/csr_proc";
declare namespace csd = "urn:ihe:iti:csd:2013";

declare function oi_csv:get_serialized($csd_doc,$requestParams) {
  let $options := 
    <csv:options>
      <csv:header value='yes'/>
    </csv:options> 

  return oi_csv:get_serialized($csd_doc,$requestParams,$options)
};

declare function oi_csv:get_serialized($csd_doc,$requestParams,$options) {
  let $csv := oi_csv:get($csd_doc,$requestParams)
  return csv:serialize($csv,$options)
};

declare function oi_csv:get($csd_doc,$requestParams) 
{
  let $csv_name := string($requestParams/@function)
  let $function := csr_proc:get_function_definition($csd_webconf:db,$csv_name)
  let $xpaths := $function/csd:extension[@type='xpaths' and @urn='urn:openhie.org:openinfoman:adapter:csv']/xpath
  let $search_func := $function/csd:extension[@type='search' and @urn='urn:openhie.org:openinfoman:adapter:csv']
  let $doc0 := 
    if ($search_func) 
    then
      let $csr :=
      <csd:careServicesRequest>
	<csd:function uuid="{$search_func}" >
	  {$requestParams}
	</csd:function>
      </csd:careServicesRequest>

      return csr_proc:process_CSR_stored_results($csd_webconf:db, $csd_doc,$csr)
    else
      $csd_doc/csd:CSD
    

  let $declare_ns := "declare namespace csd='urn:ihe:iti:csd:2013'; "
  let $entities_path := string($function/csd:extension[@type='entities' and @urn='urn:openhie.org:openinfoman:adapter:csv'])
  let $xq := $declare_ns || "declare variable $doc external; $doc" || $entities_path
  let $entities := 
    if  ($entities_path) then
      xquery:eval( $xq, map { "doc" := $doc0})
    else
      $doc0

  return
    <csv>
      {
	for $entity in  $entities
	return
	<record>
	  {
	    for $xpath in $xpaths
	    let $val :=  string(xquery:eval( $declare_ns || "declare variable $entity external; $entity/" || $xpath, map { "entity" := $entity}))  
	    let $field := element {string($xpath/@name)} {$val} 
	    return $field
	  }
	</record>
      }
      </csv>
};