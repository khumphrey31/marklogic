xquery version "1.0-ml";

module namespace plugin = "http://marklogic.com/data-hub/plugins";

import module namespace gen = "http://com.marklogic.es.uml.hr/dhfGen"
	at "/ext/hr/gen/dhfLib.xqy";

(:~
 : Create Headers Plugin
 :
 : @param $id      - the identifier returned by the collector
 : @param $content - the output of your content plugin
 : @param $options - a map containing options. Options are sent from Java
 :
 : @return - zero or more header nodes
 :)
declare function plugin:create-headers(
  $id as xs:string,
  $content as item()?,
  $options as map:map) as node()*
{
gen:createHeaders($id, $content, $options, "Department")
};
