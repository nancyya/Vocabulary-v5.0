create table supplier as
select distinct initcap(replace(replace(regexp_substr (concept_name,'(\(.*\))',1,1),'('),')')) as supplier,concept_code 
from concept_stage_sn
where concept_Class_id in ('Trade Product Unit','Trade Product Pack','Containered Pack')
and regexp_substr (concept_name,'(\(.*\))',1,1) is not null
and not regexp_like (regexp_substr (concept_name,'(\(.*\))',1,1), '[0-9]')
and not regexp_like (regexp_substr (concept_name,'(\(.*\))',1,1), 'blood|virus|inert|D|accidental|CSL|paraffin|once|extemporaneous|long chain|perindopril|triglycerides|Night Tablet')
and length(regexp_substr (concept_name,'(\(.*\))',1,1))>5
and replace(replace(regexp_substr (lower(concept_name),'(\(.*\))',1,1),'('),')')!='night'
and replace(replace(regexp_substr (lower(concept_name),'(\(.*\))',1,1),'('),')')!='capsule';

update supplier
set supplier=regexp_replace(supplier,'Night\s') where supplier like '%Night%';
update supplier
set supplier=regexp_replace(supplier,'Night\s') where supplier like '%Night%';
UPDATE SUPPLIER   SET SUPPLIER = 'Pfizer' WHERE SUPPLIER = 'Pfizer Perth'
;


--add suppliers with abbreviations
create table supplier_2 as
select distinct supplier from supplier;
INSERT INTO SUPPLIER_2 (SUPPLIER) VALUES('Apo');
INSERT INTO SUPPLIER_2 (SUPPLIER) VALUES('Sun');
INSERT INTO SUPPLIER_2 (SUPPLIER) VALUES('David Craig');
INSERT INTO SUPPLIER_2 (SUPPLIER) VALUES ('Parke Davis');
INSERT INTO SUPPLIER_2 (SUPPLIER ) VALUES ('Bioceuticals');
INSERT INTO SUPPLIER_2 (SUPPLIER ) VALUES ('Ipc');
INSERT INTO SUPPLIER_2 (SUPPLIER ) VALUES ('Rbx');
INSERT INTO SUPPLIER_2 (SUPPLIER ) VALUES ('Dakota');
INSERT INTO SUPPLIER_2 (SUPPLIER ) VALUES ('Dbl');
INSERT INTO SUPPLIER_2 (SUPPLIER ) VALUES ('Scp');
INSERT INTO SUPPLIER_2 (SUPPLIER ) VALUES ('Myx');
INSERT INTO SUPPLIER_2 (SUPPLIER ) VALUES ('Aft');
INSERT INTO SUPPLIER_2 (SUPPLIER ) VALUES ('Douglas');
INSERT INTO SUPPLIER_2 (SUPPLIER ) VALUES ('Omega');
INSERT INTO SUPPLIER_2 (SUPPLIER ) VALUES ('Bnm');
INSERT INTO SUPPLIER_2 (SUPPLIER ) VALUES ('Qv');
INSERT INTO SUPPLIER_2 (SUPPLIER ) VALUES ('Gxp');
INSERT INTO SUPPLIER_2 (SUPPLIER ) VALUES ('Fbm');
INSERT INTO SUPPLIER_2 (SUPPLIER ) VALUES ('Drla');
INSERT INTO SUPPLIER_2 (SUPPLIER ) VALUES ('Csl');
INSERT INTO SUPPLIER_2 (SUPPLIER ) VALUES ('Briemar');
INSERT INTO SUPPLIER_2 (SUPPLIER ) VALUES ('Nature''S Way');
INSERT INTO SUPPLIER_2 (SUPPLIER ) VALUES ('Sau');
INSERT INTO SUPPLIER_2 (SUPPLIER ) VALUES ('Drx');

alter table supplier_2
add concept_Code varchar(255);
update supplier_2
set concept_code='OMOP'||new_voc.nextval;

-- parse units as they looks like 'mg/ml' etc.
create table unit as ( 
SELECT distinct concept_name,CONCEPT_CLASS_ID,NEW_CONCEPT_CLASS_ID,concept_name as CONCEPT_CODE,UNITID from (
select distinct
trim(regexp_substr(regexp_replace(b.concept_name,'(/)(unit|each|application|dose)') , '[^/]+', 1, levels.column_value))  as concept_name, 'Unit' as NEW_CONCEPT_CLASS_ID,CONCEPT_CLASS_ID,UNITID
from ds_0 a join concept_stage_sn  b on UNITID=concept_code,
table(cast(multiset(select level from dual connect by  level <= length (regexp_replace(b.concept_name, '[^/]+'))  + 1) as sys.OdciNumberList)) levels) where concept_name is not null);

drop table form;
create table form as
select distinct a.CONCEPT_NAME, 'Dose Form' as NEW_CONCEPT_CLASS_ID,a.CONCEPT_CODE,a.CONCEPT_CLASS_ID from
concept_stage_sn a join SCT2_RELA_FULL_AU b on a.concept_code=b.sourceid join concept_stage_sn  c on c.concept_Code=destinationid where a.concept_class_id='AU Qualifier' 
and a.concept_code not in 
(select distinct a.concept_code from 
concept_stage_sn a join RF2_FULL_RELATIONSHIPS b on a.concept_code=b.sourceid join concept_stage_sn  c on c.concept_Code=destinationid where a.concept_class_id='AU Qualifier'
and initcap(c.concept_name) in ('Area Unit Of Measure','Biological Unit Of Measure','Composite Unit Of Measure','Descriptive Unit Of Measure','Mass Unit Of Measure','Microbiological Culture Unit Of Measure',
'Radiation Activity Unit Of Measure','Time Unit Of Measure','Volume Unit Of Measure','Type Of International Unit','Type Of Pharmacopoeial Unit'))
and lower(a.concept_name) not in (select lower(concept_name) from unit);


create table dcs_bn as select distinct * from concept_stage_sn  where CONCEPT_CLASS_ID='Trade Product';
update dcs_bn 
set concept_name=regexp_replace(concept_name,'\d+(\.\d+)?(\s\w+)?/\d+\s\w+$') where regexp_like(concept_name,'\d+(\s\w+)?/\d+\s\w+$');
update dcs_bn 
set concept_name=regexp_replace(concept_name,'(\d+/)?(\d+\.)?\d+/\d+(\.\d+)?$') where regexp_like(concept_name,'(\d+/)?(\d+\.)?\d+/\d+(\.\d+)?$') and not regexp_like (concept_name,'-(\d+\.)?\d+/\d+$');
update dcs_bn 
set concept_name=regexp_replace(concept_name,'\d+(\.\d+)?/\d+(\.\d+)?(\s)?\w+$')where regexp_like(concept_name,'\d+(\.\d+)?/\d+(\.\d+)?(\s)?\w+$');
update dcs_bn 
set concept_name=regexp_replace(concept_name,'\d+(\.\d+)?(\s)?(\w+)?(\s\w+)?/\d+(\.\d+)?(\s)?\w+$') where regexp_like(concept_name,'\d+(\.\d+)?(\s)?(\w+)?(\s\w+)?/\d+(\.\d+)?(\s)?\w+$');
update dcs_bn 
set concept_name='Biostate' where regexp_like(concept_name,'Biostate');
update dcs_bn 
set concept_name=rtrim(trim(regexp_replace(regexp_substr(concept_name,'\w+(-)?(\s)?(\w+)?'),'\d+')),'-') where regexp_like(concept_name,'/') and concept_name not like '%Neutrogena%';

delete dcs_bn where  CONCEPT_CODE in (select CONCEPT_CODE from non_drug);
delete dcs_bn where regexp_like(lower(concept_name),'chloride|phosphate|paraffin|water| acid|toxoid|hydrate|sodium|glucose|castor| talc|^iodine|antivenom')
and not regexp_like(concept_name,' APF| CD|Forte|Relief|Adult|Bio |BCP| XR|Plus|SR|Minims|HCTZ| BP|lasma-Lyte| EC|Min-I-Jet');
update  dcs_bn
set concept_name=replace(concept_name,'(Pfizer (Perth))','Pfizer');

UPDATE DCS_BN
SET CONCEPT_NAME = 'Paracetamol Infant Drops' WHERE CONCEPT_NAME = 'Paracetamol Infant''s Drops';
UPDATE DCS_BN
   SET CONCEPT_NAME = 'Panadol Children''s 5 to 12 Years'
WHERE CONCEPT_NAME = 'Panadol Children''s 5 Years to 12 Years';
UPDATE DCS_BN
   SET CONCEPT_NAME = 'Panadol Children''s 1 to 5 Years'
WHERE CONCEPT_NAME = 'Panadol Children''s Elixir 1 to 5 Years';
UPDATE DCS_BN
   SET CONCEPT_NAME = 'Panadol Children''s 5 to 12 Years'
WHERE CONCEPT_NAME = 'Panadol Children''s Elixir 5 to 12 Years';
update  dcs_bn
set concept_name=regexp_replace(concept_name,'\(Day\)|\(Night\)');
update  dcs_bn
set concept_name=trim(replace(regexp_replace(concept_name,'\d+|\.|%|\smg\s|\smg$|\sIU\s|\sIU$'),'  ',' '))
where not regexp_like (concept_name,'-\d+') and length (concept_name)>3 and concept_name not like '%Years%'
;
delete dcs_bn where concept_name like '% mg%' or concept_name in ('Aciclovir Intravenous','Aciclovir IV','Acidophilus Bifidus','Risperidone','Ropivacaine','Piperacillin And Tazobactam','Perindopril And Indapamide','Paracetamol IV','Paracetamol Drops''Ondansetron Tabs','Omeprazole IV','Olanzapine IM',
'Copper, Chromium and Manganese','Menthol and Eucalyptus Inhalation','Menthol and Pine Inhalation','Chlorhexidine Hand Lotion','Brilliant Green and Crystal Violet Paint','Chlorhexidine Acetate and Cetrimide','Metoprolol IV','Metformin',
'Methadone Syrup','Levetiracetam IV','Latanoprost-Timolol','Vitamin B','Multivitamin and Minerals','Mycostatin Oral Drops','Paracetamol Drops','Nystatin Drops');
delete dcs_bn where lower(concept_name) in (select lower(Concept_name) from concept_stage_sn  where CONCEPT_CLASS_ID='AU Substance');
delete dcs_bn where lower(concept_name) in (select lower(Concept_name) from devv5.concept  where CONCEPT_CLASS_ID='Ingredient');

truncate table DRUG_concept_STAGE;
insert into DRUG_concept_STAGE (CONCEPT_NAME,VOCABULARY_ID,CONCEPT_CLASS_ID,STANDARD_CONCEPT,CONCEPT_CODE,POSSIBLE_EXCIPIENT,domain_id,VALID_START_DATE,VALID_END_DATE,INVALID_REASON, SOURCE_CONCEPT_CLASS_ID)
select distinct CONCEPT_NAME, 'AMT', NEW_CONCEPT_CLASS_ID, '', CONCEPT_CODE, '','Drug', TO_DATE('2016/11/01', 'yyyy/mm/dd') as valid_start_date,TO_DATE('2099/12/31', 'yyyy/mm/dd') as valid_end_date, '',CONCEPT_CLASS_ID
 from 
(
select distinct CONCEPT_NAME,'Ingredient' as NEW_CONCEPT_CLASS_ID,CONCEPT_CODE,CONCEPT_CLASS_ID from concept_stage_sn  where CONCEPT_CLASS_ID='AU Substance' --or CONCEPT_CLASS_ID='Medicinal Product'
union 
select distinct CONCEPT_NAME, 'Brand Name' as NEW_CONCEPT_CLASS_ID,CONCEPT_CODE,CONCEPT_CLASS_ID from dcs_bn
union
select distinct CONCEPT_NAME, NEW_CONCEPT_CLASS_ID,CONCEPT_CODE,CONCEPT_CLASS_ID from form
union
select supplier,'Supplier',concept_code,'' from supplier_2
union
select distinct CONCEPT_NAME, NEW_CONCEPT_CLASS_ID,initcap(CONCEPT_NAME),CONCEPT_CLASS_ID from unit
union
select distinct CONCEPT_NAME,'Drug Product',CONCEPT_CODE,CONCEPT_CLASS_ID from concept_stage_sn  where CONCEPT_CLASS_ID in ('Containered Pack','Med Product Pack','Trade Product Pack','Med Product Unit','Trade Product Unit')
and CONCEPT_NAME not like '%(&)%' and  REGEXP_COUNT(concept_name,'\sx\s')<=1 and concept_name not like '%Trisequens, 28%'--exclude packs
union 
select distinct substr(CONCEPT_NAME,1,242)||' [Drug Pack]' as concept_name,'Drug Product',CONCEPT_CODE,CONCEPT_CLASS_ID from concept_stage_sn  where 
CONCEPT_CLASS_ID in ('Containered Pack','Med Product Pack','Trade Product Pack','Med Product Unit','Trade Product Unit')
and (CONCEPT_NAME like '%(&)%' or  REGEXP_COUNT(concept_name,'\sx\s')>1 or concept_name like '%Trisequens, 28%')
 );  
DELETE DRUG_CONCEPT_STAGE WHERE CONCEPT_CODE in (select CONCEPT_CODE from non_drug);

insert into DRUG_concept_STAGE (CONCEPT_NAME,VOCABULARY_ID,CONCEPT_CLASS_ID,STANDARD_CONCEPT,CONCEPT_CODE,POSSIBLE_EXCIPIENT,domain_id,VALID_START_DATE,VALID_END_DATE,INVALID_REASON, SOURCE_CONCEPT_CLASS_ID)
select distinct CONCEPT_NAME, 'AMT', 'Device', '', CONCEPT_CODE, '','Device', TO_DATE('2016/11/01', 'yyyy/mm/dd') as valid_start_date,TO_DATE('2099/12/31', 'yyyy/mm/dd') as valid_end_date, '',CONCEPT_CLASS_ID
from non_drug where concept_Class_id not in ('AU Qualifier','AU Substance','Trade Product');

 
update drug_concept_stage 
set concept_name=INITCAP(concept_name);--to fix chloride\Chloride

delete drug_concept_stage --delete containers
where concept_code in (
select distinct destinationid from concept_stage_sn  a join SCT2_RELA_FULL_AU b on destinationid=a.concept_code
join concept_stage_sn  c on c.concept_code=sourceid
 where  typeid='30465011000036106');
 

MERGE --there are names duplicates due to original data mistakes 
INTO    drug_concept_stage dcs
USING   (
select concept_name, MIN(concept_code) m from drug_concept_stage WHERE concept_class_id in ('Ingredient','Dose Form','Brand Name','Unit') --and  source_concept_class_id not in ('Medicinal Product','Trade Product')
group by concept_name having count(concept_name) >= 1
) d ON (d.m=dcs.concept_code)
WHEN MATCHED THEN UPDATE
    SET dcs.standard_concept = 'S'
;
UPDATE drug_concept_stage
SET POSSIBLE_EXCIPIENT='1'
WHERE concept_name='Aqueous Cream';

delete  drug_concept_stage where lower(concept_name) in ('containered trade product pack','trade product pack','medicinal product unit of use','trade product unit of use','form','medicinal product pack','unit of use', 'unit of measure');

delete  drug_concept_stage where initcap(concept_name) in --delete all unnecessary concepts
('Alternate Strength Followed By Numerator/Denominator Strength','Alternate Strength Only','Australian Qualifier','Numerator/Denominator Strength','Numerator/Denominator Strength Followed By Alternate Strength','Preferred Strength Representation Type','Area Unit Of Measure','Square','Kbq','Dispenser Pack','Diluent','Tube','Tub','Carton','Unit Dose','Vial','Strip',
'Biological Unit Of Measure','Composite Unit Of Measure','Descriptive Unit Of Measure','Medicinal Product','Mass Unit Of Measure','Microbiological Culture Unit Of Measure','Radiation Activity Unit Of Measure','Time Unit Of Measure','Australian Substance','Medicinal Substance','Volume Unit Of Measure',
'Measure','Continuous','Dose','Ampoule','Bag','Bead','Bottle','Ampoule','Type Of International Unit','Type Of Pharmacopoeial Unit');

delete drug_concept_stage --as RxNorm doesn't have diluents in injectable drugs we will also delete them
where (lower(concept_name) like '%inert%' or lower(concept_name) like '%diluent%') 
and concept_class_id='Drug Product' and lower(concept_name) not like '%tablet%';


CREATE INDEX dcs_index ON drug_concept_stage (concept_code);