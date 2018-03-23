# Block Factory Example

This gradle project shows the transformation of UML models to entity services models. 

## Intro

This example shows the following:
- How to model in UML movies and their relationships
- How to model and implement denormalization relationships. 
- How to map the UML model to a MarkLogic Entity Services model.
- How to ingest source block data into a MarkLogic database so that it conforms to the model.

## The Cooking Show Approach

Like a cooking show, this example describes how to prepare the souffle but also gives a souffle already prepred for you to consume. 

The "prepared" souffle includes:
- The UML model.
- MLCP gradle tasks to ingest block source data and transform it to the form of the model
- ES instance converter already modified to address source-to-model mapping issues. Used in MLCP tasks.

If you were to start from scratch, you would follow this recipe:
- Devise the UML model in your favorite UML editor.
- Use the XMI to ES transformation to map the UML model to Entity Services. 
- From the Entity Services model, generate the instance converter.
- Tweak the instance converter to propertly map source fields to model fields. 
- In your gradle build file, add MLCP tasks to ingest data. 

## How to run:

Our project uses gradle. Before running, view the settings in gradle.properties. Create a file called gradle-local.properties and in this file override any of the properties from gradle.properties.

Here are the steps to setup.

### Setup DB
Setup new DB. Will use basic DB config with no indexes. Will bring in XMI2ES transform to our modules.

Run the following:

gradle -PenvironmentName=local -i clearGenerated useInitialDBConfig includeXMI2ESTransform mlDeploy

Confirm:
- Content DB has no element range indexes
- Modules DB has /xmi2es/loadXMITransformation.xqy
- No documents having URI containing GENERATED in modules, content, or schemas DB.

### Transform UML to ES
Move our UML model into ML as an ES model. Then generate ES artifacts

Run the following:

gradle -PenvironmentName=local -i ingestModel mlgen

Confirm:
- Content DB has the following documents
  - /marklogic.com/entity-services/models/BlockFactory.xml
  - /xmi2es/es/BlockFactory.xml
  - /xmi2es/findings/BlockFactory.xml
  - /xmi2es/xmi/BlockFactory.xml

- In gradle project we now have these files:
  - src/main/ml-config/databases/content-database-GENERATED.json
(Generated DB config with indexes specified in model. We will use this.)
  - src/main/ml-modules/ext/entity-services/BlockFactory-0.0.1-GENERATED.xqy
(Generated instance converter. We need to tweak this a little. The finished product is included in the same folder: BlockFactory-0.0.1.xqy)
  - src/main/ml-modules/options/BlockFactory.xml
(Generated search options.)
  - src/main/ml-schemas/BlockFactory-0.0.1.xsd
(Generated XML schema.)
  - src/main/ml-schemas/tde/BlockFactory-0.0.1-GENERATED.tdex
(Generated TDE template. We need to tweak this a little. The finished product is includes in the same folder: BlockFactory-0.0.1.tdex.)

### Deploy
Deploy these artifacts: DB indexes, modules and schemas. IT IS VERY IMPORTANT TO DELETE THE GENERATED TDE TEMPLATE!!!

Run the following:

gradle -PenvironmentName=local -i useGeneratedDBConfig deleteGeneratedTDE mlDeployDatabases mlReloadModules mlReloadSchemas

Confirm:
- Content DB now has element range indexes
- Schemas DB has ONLY ONE tdex document: /BlockFactory-0.0.1.tdex

### Ingest
Ingest movie data based on the model

Run the following:

gradle -PenvironmentName=local -i ingestMovie

Confirm:
- Content DB now has the movie documents. Check the totals per collection. 
  - bios:2
  - companies:1
  - movies:5
  - movieDocs:2
  - persons:3
  - roles:12

If your count is different, it might be because you have two TDE templates. Go back to step 3 and confirm the results.

## Explore Data
In Query Console, import XMI2ESBlockFactory.xml workspace. In each tab, try the query to explore an aspect of the data.
