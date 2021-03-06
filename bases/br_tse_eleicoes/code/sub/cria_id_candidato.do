
//----------------------------------------------------------------------------//
// build: id_candidato
//----------------------------------------------------------------------------//

use "output/candidatos_1998.dta", clear
append using "output/candidatos_2000.dta"
append using "output/candidatos_2002.dta"
append using "output/candidatos_2004.dta"
append using "output/candidatos_2006.dta"
append using "output/candidatos_2008.dta"
append using "output/candidatos_2010.dta"
append using "output/candidatos_2012.dta"
append using "output/candidatos_2014.dta"
append using "output/candidatos_2016.dta"
append using "output/candidatos_2018.dta"
append using "output/candidatos_2020.dta"

//--------------------//
// limpa entradas erradas
//--------------------//

drop if CPF == "#NULO#" | CPF == "000000000-4" | CPF == "0" | CPF == "00000000000"
drop if titulo_eleitoral == "000000000000" | titulo_eleitoral == "#NI#"

compress

//--------------------//
// 1a rodada
// usa CPF and titulo_eleitoral
//--------------------//

keep nome_candidato CPF titulo_eleitoral
duplicates drop

egen id_candidato_BD = group(CPF titulo_eleitoral), missing
la var id_candidato_BD "ID Candidato - Base dos Dados"

bys CPF: egen aux_id_number_CPF = max(id_candidato_BD)
replace id_candidato_BD = aux_id_number_CPF

bys titulo_eleitoral: egen aux_id_number_TE = max(id_candidato_BD)
replace id_candidato_BD = aux_id_number_TE

egen aux_CPF = tag(id_candidato_BD CPF)
bys id_candidato_BD: egen N_CPF = sum(aux_CPF)

egen aux_TE = tag(id_candidato_BD titulo_eleitoral)
bys id_candidato_BD: egen N_TE = sum(aux_TE)

drop aux*

duplicates tag id_cand, gen(dup)

order    id_candidato_BD N_CPF N_TE CPF titulo_eleitoral nome_candidato
sort dup id_candidato_BD N_CPF N_TE CPF titulo_eleitoral

preserve
	keep if N_CPF > 1 & N_TE > 1
	save "tmp/para_2a_rodada.dta", replace
restore

keep if N_CPF == 1 | N_TE == 1

keep id_candidato_BD CPF titulo_eleitoral nome_candidato

save "tmp/1a_rodada.dta", replace

//--------------------//
// 2a rodada
// separar por nomes
//--------------------//

use "tmp/para_2a_rodada.dta", clear

gen nome_candidato_limpo = nome_candidato
clean_string nome_candidato_limpo

gen aux_primeira = word(nome_candidato_limpo, 1)
gen aux_ultima = word(nome_candidato_limpo, -1)

// consertando strings erradas identificadas no olho
replace aux_primeira = "elves"		if aux_primeira == "elvis" & aux_ultima == "leite"
replace aux_primeira = "lourival"	if aux_primeira == "luciano" & aux_ultima == "dombroski"
replace aux_primeira = "vanderley"	if aux_primeira == "vanderlley" & aux_ultima == "passos"
replace aux_primeira = "manoel"		if aux_primeira == "manuel" & aux_ultima == "santos"
replace aux_primeira = "daizymar"	if aux_primeira == "deizymar" & aux_ultima == "messini"
replace aux_primeira = "moacir"		if aux_primeira == "moacy" & aux_ultima == "evangelista"

replace aux_ultima = "pontim"		if aux_primeira == "antonio" & aux_ultima == "pontin"
replace aux_ultima = "messine"		if aux_primeira == "daizymar" & aux_ultima == "messini"
replace aux_ultima = "ortigosa"		if aux_primeira == "ideraldo" & aux_ultima == "ortigossa"
replace aux_ultima = "rezende"		if aux_primeira == "cecilio" & aux_ultima == "resende"
replace aux_ultima = "souza"		if aux_primeira == "antonio" & aux_ultima == "sousa"
replace aux_ultima = "paula"		if aux_primeira == "nuncia" & aux_ultima == "souza"
replace aux_ultima = "silva"		if aux_primeira == "custodia" & aux_ultima == "sessim"
replace aux_ultima = "soares"		if aux_primeira == "rosangela" & aux_ultima == "dantas"

egen aux_nomes = tag(id_candidato_BD aux_primeira aux_ultima)
bys id_candidato_BD: egen N_nomes = sum(aux_nomes)

egen aux_id = group(id_candidato_BD aux_primeira aux_ultima)
replace id_candidato_BD = 100000000 + aux_id	// para diferenciar de id_candidato em linhas
format id_candidato_BD %20.0g

keep id_candidato_BD CPF titulo_eleitoral nome_candidato

save "tmp/2a_rodada.dta", replace

//--------------------//
// append
//--------------------//

use "tmp/1a_rodada.dta", clear
append using "tmp/2a_rodada.dta"

ren  id_candidato_BD aux_id
egen id_candidato_BD = group(aux_id)
la var id_candidato_BD "ID Candidato - Base dos Dados"

sort  id_candidato_BD
order id_candidato_BD CPF titulo_eleitoral nome_candidato
keep  id_candidato_BD CPF titulo_eleitoral nome_candidato

compress

save "output/id_candidato_BD.dta", replace
