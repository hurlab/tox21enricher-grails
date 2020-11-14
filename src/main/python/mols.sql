CREATE OR REPLACE FUNCTION public.get_mfp2_neighbors(smiles text)
 RETURNS TABLE(casrn character varying, m mol, similarity double precision, cyanide integer, isocyanate integer, aldehyde integer, epoxide integer)
 LANGUAGE sql
 STABLE
AS $function$
select casrn,m,tanimoto_sml(morganbv_fp(mol_from_smiles($1::cstring)),mfp2) as similarity,cyanide,isocyanate,aldehyde,epoxide
from fps join mols using (casrn)
where morganbv_fp(mol_from_smiles($1::cstring))%mfp2
order by morganbv_fp(mol_from_smiles($1::cstring))<%>mfp2;
$function$