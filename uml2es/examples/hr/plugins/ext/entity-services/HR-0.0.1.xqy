xquery version '1.0-ml';

(:
 This module was generated by MarkLogic Entity Services.
 The source model was HR-0.0.1

 For usage and extension points, see the Entity Services Developer's Guide

 https://docs.marklogic.com/guide/entity-services

 After modifying this file, put it in your project for deployment to the modules
 database of your application, and check it into your source control system.

 Generated at timestamp: 2018-01-12T16:12:40.377824-05:00
 :)

module namespace hR
    = 'http://com.marklogic.es.uml.hr#HR-0.0.1';

import module namespace es = 'http://marklogic.com/entity-services'
    at '/MarkLogic/entity-services/entity-services.xqy';

import module namespace json = "http://marklogic.com/xdmp/json"
    at "/MarkLogic/json/json.xqy";





declare option xdmp:mapping 'false';


(:~
 : Extracts instance data, as a map:map, from some source document.
 : @param $source-node  A document or node that contains
 :   data for populating a Department
 : @return A map:map instance with extracted data and
 :   metadata about the instance.
 :)
declare function hR:extract-instance-Department(
    $source as item()?
) as map:map
{
    (: IMPL - map to fields from Global source file :)

    let $source-node := es:init-source($source, 'Department')
    let $departmentId  :=             $source-node/dept_num ! xs:int(.)
    let $departmentName  :=               $source-node/dept_name ! xs:string(.) 
    let $instance := es:init-instance($source-node, 'Department')
    (: Comment or remove the following line to suppress attachments :)
        =>es:add-attachments($source)

    return
    if (empty($source-node/*))
    then $instance
    else $instance
        =>   map:with('departmentId', $departmentId)
        =>   map:with('departmentName', $departmentName)
};

(:~
 : Extracts instance data, as a map:map, from some source document.
 : @param $source-node  A document or node that contains
 :   data for populating a Employee
 : @return A map:map instance with extracted data and
 :   metadata about the instance.
 :)
declare function hR:extract-instance-Employee(
    $source as item()?
) as map:map
{
    (: IMPL - several changes. Primarily allow formats from both ACME and Global. Others, see below. :)

    let $source-node := es:init-source($source, 'Employee')

    (: These fields are in both ACME and Global. Notice how we select source field as either-or express:  (a,b)[1] :)
    let $employeeId  := ($source-node/id, $source-node/emp_id)[1] ! xs:int(.)
    let $firstName  :=  ($source-node/firstName, $source-node/first_name)[1] ! xs:string(.)
    let $lastName  :=   ($source-node/lastName, $source-node/last_name)[1] ! xs:string(.)
    let $hireDate  :=   xdmp:parse-dateTime("[M01]/[D01]/[Y0001]", string(($source-node/hireDate, $source-node/hire_date)[1]))  ! xs:date(.)
    let $dateOfBirth  :=   xdmp:parse-dateTime("[M01]/[D01]/[Y0001]", string(($source-node/dateOfBirth, $source-node/dob)[1]))  ! xs:date(.)

    (: These fields are Global only :)
    let $officeNumber  :=             $source-node/office_number ! xs:int(.)
    let $title  :=             $source-node/job_title ! xs:string(.) 

    (:
    Now for salary. For global it's in a different doc. For ACME it's in the main doc under salary history - and we need most recent.
    :)
    let $salary-doc := 
        if (exists($source-node/emp_id) = true()) then 
            es:init-source(fn:doc(concat("/hr/salary/global/", $employeeId, ".xml")), "Salary")/es:instance
        else 
            let $latest-effective-date := xs:date("1900-01-01")
            let $latest-doc := ()
            let $_ := for $sal in $source-node//salaryHistory return 
              let $this-effective-date := xs:date(xdmp:parse-dateTime("[M01]/[D01]/[Y0001]", string($sal/effectiveDate)))
              return
                if ($this-effective-date gt $latest-effective-date) then xdmp:set($latest-doc, $sal)
                else ()
            return $latest-doc

    let $status  :=   ($salary-doc/status, "acquired")[1] ! xs:string(.)
    let $effectiveDate  :=  xdmp:parse-dateTime("[M01]/[D01]/[Y0001]", string(($salary-doc/job_effective_date, $salary-doc/effectiveDate)[1])) ! xs:date(.)
    let $baseSalary  := string(($salary-doc/base_salary, $salary-doc/salary)[1]) ! xs:float(.)
    let $bonus  := 
        if (exists($salary-doc/bonus)) then  $salary-doc/bonus ! xs:float(.)
        else ()

    (: address for global only :)
    let $addresses  := 
        if (string-length($source-node/addr1) gt 0) then 
            es:extract-array($source-node, hR:extract-instance-Address#1)
        else ()

    (: Now for child arrays. All the fields are at the main level in the GLobal employee. So we need some finesse to keep with generated ES convereter code :)
    let $phone-spec := (("home", "home_phone"), ("mobile", "mobile"), ("pager", "pager"), ("work", "work_phone"))
    let $phones  := json:to-array(
        for $phone at $pindex in $phone-spec return
            if (($pindex mod 2) eq 0) then
                let $phone-type := $phone-spec[$pindex - 1]
                let $phone-field := $phone-spec[$pindex]
                let $phone-value := $source-node/*[name()=$phone-field] ! xs:string(.) 
                return 
                    if (string-length($phone-value) gt 0) then hR:extract-instance-Phone($source-node, $phone-type, $phone-value)
                    else ()
            else ()
    )

    let $email-spec := (("home", "home_email"), ("work", "work_email"))
    let $emails  := json:to-array(
        for $email at $eindex in $email-spec return
            if (($eindex mod 2) eq 0) then
                let $email-type := $email-spec[$eindex - 1]
                let $email-field := $email-spec[$eindex]
                let $email-value := $source-node/*[name()=$email-field] ! xs:string(.) 
                return 
                    if (string-length($email-value) gt 0) then hR:extract-instance-Email($source-node, $email-type, $email-value)
                    else ()
            else ()
    )

    let $instance := es:init-instance($source-node, 'Employee')
    (: Comment or remove the following line to suppress attachments :)
        =>es:add-attachments($source)

    return
    if (empty($source-node/*))
    then $instance
    else $instance
        =>   map:with('employeeId', $employeeId)
        =>   map:with('status', $status)
        =>   map:with('firstName', $firstName)
        =>   map:with('lastName', $lastName)
        =>es:optional('effectiveDate', $effectiveDate)
        =>   map:with('hireDate', $hireDate)
        =>es:optional('baseSalary', $baseSalary)
        =>es:optional('bonus', $bonus)
        =>   map:with('dateOfBirth', $dateOfBirth)
        =>es:optional('addresses', $addresses)
        =>es:optional('phones', $phones)
        =>es:optional('emails', $emails)
        =>es:optional('officeNumber', $officeNumber)
        =>es:optional('title', $title)
};

(:~
 : Extracts instance data, as a map:map, from some source document.
 : @param $source-node  A document or node that contains
 :   data for populating a Address
 : @return A map:map instance with extracted data and
 :   metadata about the instance.
 :)
declare function hR:extract-instance-Address(
    $source as item()?
) as map:map
{

    (: IMPL map to fields from Global source file :)

    let $source-node := es:init-source($source, 'Address')
    let $addressType  :=  "Primary"
    let $lines  := json:to-array(($source-node/addr1, $source-node/addr2))
    let $city  :=             $source-node/city ! xs:string(.)
    let $state  :=             $source-node/state ! xs:string(.)
    let $zip  :=             $source-node/zip ! xs:string(.)
    let $country  := "USA"
    (: The following property is a local reference.  :)
    let $geoCoordinates  :=               $source-node! hR:extract-instance-GeoCoordinates(.) 
    let $instance := es:init-instance($source-node, 'Address')
    (: Comment or remove the following line to suppress attachments :)
        =>es:add-attachments($source)

    return
    if (empty($source-node/*))
    then $instance
    else $instance
        =>   map:with('addressType', $addressType)
        =>   map:with('lines', $lines)
        =>   map:with('city', $city)
        =>   map:with('state', $state)
        =>   map:with('zip', $zip)
        =>   map:with('country', $country)
        =>es:optional('geoCoordinates', $geoCoordinates)
};

(:~
 : Extracts instance data, as a map:map, from some source document.
 : @param $source-node  A document or node that contains
 :   data for populating a GeoCoordinates
 : @return A map:map instance with extracted data and
 :   metadata about the instance.
 :)
declare function hR:extract-instance-GeoCoordinates(
    $source as item()?
) as map:map
{
    let $source-node := es:init-source($source, 'GeoCoordinates')
    let $latitude  :=             $source-node/latitude ! xs:float(.)
    let $longitude  :=             $source-node/longitude ! xs:float(.) 
    let $instance := es:init-instance($source-node, 'GeoCoordinates')
    (: Comment or remove the following line to suppress attachments :)
        =>es:add-attachments($source)

    return
    if (empty($source-node/*))
    then $instance
    else $instance
        =>   map:with('latitude', $latitude)
        =>   map:with('longitude', $longitude)
};

(:~
 : Extracts instance data, as a map:map, from some source document.
 : @param $source-node  A document or node that contains
 :   data for populating a Phone
 : @return A map:map instance with extracted data and
 :   metadata about the instance.
 :)
declare function hR:extract-instance-Phone(
    $source as item()?, $phone-type as xs:string, $phone-number as xs:string
) as map:map
{
    (: IMPL - changed this so that we pass in the value. See Employee. :)

    let $source-node := es:init-source($source, 'Phone')
    let $instance := es:init-instance($source-node, 'Phone')
    (: Comment or remove the following line to suppress attachments :)
        =>es:add-attachments($source)

    return
    if (empty($source-node/*)) then $instance
    else $instance
        =>   map:with('phoneType', $phone-type)
        =>   map:with('phoneNumber', $phone-number)
};

(:~
 : Extracts instance data, as a map:map, from some source document.
 : @param $source-node  A document or node that contains
 :   data for populating a Email
 : @return A map:map instance with extracted data and
 :   metadata about the instance.
 :)
declare function hR:extract-instance-Email(
    $source as item()?, $email-type as xs:string, $email-address as xs:string
) as map:map
{
    (: IMPL - changed this so that we pass in the value. See Employee. :)

    let $source-node := es:init-source($source, 'Email')
    let $instance := es:init-instance($source-node, 'Email')
    (: Comment or remove the following line to suppress attachments :)
        =>es:add-attachments($source)

    return
    if (empty($source-node/*)) then $instance
    else $instance
        =>   map:with('emailType', $email-type)
        =>   map:with('emailAddress', $email-address)
};





(:~
 : Turns an entity instance into a canonical document structure.
 : Results in either a JSON document, or an XML document that conforms
 : to the entity-services schema.
 : Using this function as-is should be sufficient for most use
 : cases, and will play well with other generated artifacts.
 : @param $entity-instance A map:map instance returned from one of the extract-instance
 :    functions.
 : @param $format Either "json" or "xml". Determines output format of function
 : @return An XML element that encodes the instance.
 :)
declare function hR:instance-to-canonical(

    $entity-instance as map:map,
    $instance-format as xs:string
) as node()
{

        if ($instance-format eq "json")
        then xdmp:to-json( hR:canonicalize($entity-instance) )/node()
        else hR:instance-to-canonical-xml($entity-instance)
};


(:~
 : helper function to turn map structure of an instance, which uses specialized
 : keys to encode metadata, into a document tree, which uses the node structure
 : to encode all type and property information.
 :)
declare private function hR:canonicalize(
    $entity-instance as map:map
) as map:map
{
    json:object()
    =>map:with( map:get($entity-instance,'$type'),
                if ( map:contains($entity-instance, '$ref') )
                then fn:head( (map:get($entity-instance, '$ref'), json:object()) )
                else
                let $m := json:object()
                let $_ :=
                    for $key in map:keys($entity-instance)
                    let $instance-property := map:get($entity-instance, $key)
                    where ($key castable as xs:NCName)
                    return
                        typeswitch ($instance-property)
                        (: This branch handles embedded objects.  You can choose to prune
                           an entity's representation of extend it with lookups here. :)
                        case json:object
                            return
                                if (empty(map:keys($instance-property)))
                                then map:put($m, $key, json:object())
                                else map:put($m, $key, hR:canonicalize($instance-property))
                        (: An array can also treated as multiple elements :)
                        case json:array
                            return
                                (
                                for $val at $i in json:array-values($instance-property)
                                return
                                    if ($val instance of json:object)
                                    then json:set-item-at($instance-property, $i, hR:canonicalize($val))
                                    else (),
                                map:put($m, $key, $instance-property)
                                )

                        (: A sequence of values should be simply treated as multiple elements :)
                        (: TODO is this lossy? :)
                        case item()+
                            return
                                for $val in $instance-property
                                return map:put($m, $key, $val)
                        default return map:put($m, $key, $instance-property)
                return $m)
};





(:~
 : Turns an entity instance into an XML structure.
 : This out-of-the box implementation traverses a map structure
 : and turns it deterministically into an XML tree.
 : Using this function as-is should be sufficient for most use
 : cases, and will play well with other generated artifacts.
 : @param $entity-instance A map:map instance returned from one of the extract-instance
 :    functions.
 : @return An XML element that encodes the instance.
 :)
declare private function hR:instance-to-canonical-xml(
    $entity-instance as map:map
) as element()
{
    (: Construct an element that is named the same as the Entity Type :)
    let $namespace := map:get($entity-instance, "$namespace")
    let $namespace-prefix := map:get($entity-instance, "$namespacePrefix")
    let $nsdecl :=
        if ($namespace) then
        namespace { $namespace-prefix } { $namespace }
        else ()
    let $type-name := map:get($entity-instance, '$type')
    let $type-qname :=
        if ($namespace)
        then fn:QName( $namespace, $namespace-prefix || ":" || $type-name)
        else $type-name
    return
        element { $type-qname }  {
            $nsdecl,
            if ( map:contains($entity-instance, '$ref') )
            then map:get($entity-instance, '$ref')
            else
                for $key in map:keys($entity-instance)
                let $instance-property := map:get($entity-instance, $key)
                let $ns-key :=
                    if ($namespace and $key castable as xs:NCName)
                    then fn:QName( $namespace, $namespace-prefix || ":" || $key)
                    else $key
                where ($key castable as xs:NCName)
                return
                    typeswitch ($instance-property)
                    (: This branch handles embedded objects.  You can choose to prune
                       an entity's representation of extend it with lookups here. :)
                    case json:object+
                        return
                            for $prop in $instance-property
                            return element { $ns-key } { hR:instance-to-canonical-xml($prop) }
                    (: An array can also treated as multiple elements :)
                    case json:array
                        return
                            for $val in json:array-values($instance-property)
                            return
                                if ($val instance of json:object)
                                then element { $ns-key } {
                                    attribute datatype { 'array' },
                                    hR:instance-to-canonical-xml($val)
                                }
                                else element { $ns-key } {
                                    attribute datatype { 'array' },
                                    $val }
                    (: A sequence of values should be simply treated as multiple elements :)
                    case item()+
                        return
                            for $val in $instance-property
                            return element { $ns-key } { $val }
                    default return element { $ns-key } { $instance-property }
        }
};


(:
 : Wraps a canonical instance (returned by instance-to-canonical())
 : within an envelope patterned document, along with the source
 : document, which is stored in an attachments section.
 : @param $entity-instance an instance, as returned by an extract-instance
 : function
 : @param $entity-format Either "json" or "xml", selects the output format
 : for the envelope
 : @return A document which wraps both the canonical instance and source docs.
 :)
declare function hR:instance-to-envelope(
    $entity-instance as map:map,
    $envelope-format as xs:string
) as document-node()
{
    let $canonical := hR:instance-to-canonical($entity-instance, $envelope-format)
    let $attachments := es:serialize-attachments($entity-instance, $envelope-format)
    return
    if ($envelope-format eq "xml")
    then
        document {
            element es:envelope {
                element es:instance {
                    element es:info {
                        element es:title { map:get($entity-instance,'$type') },
                        element es:version { '0.0.1' }
                    },
                    $canonical
                },
                $attachments
            }
        }
    else
    document {
        object-node { 'envelope' :
            object-node { 'instance' :
                object-node { 'info' :
                    object-node {
                        'title' : map:get($entity-instance,'$type'),
                        'version' : '0.0.1'
                    }
                }
                +
                $canonical
            }
            +
            $attachments
        }
    }
};


(:
 : @param $entity-instance an instance, as returned by an extract-instance
 : function
 : @return A document which wraps both the canonical instance and source docs.
 :)
declare function hR:instance-to-envelope(
    $entity-instance as map:map
) as document-node()
{
    hR:instance-to-envelope($entity-instance, "xml")
};



