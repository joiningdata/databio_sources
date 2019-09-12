BUILD=`curl -sL 'https://rest.ensembl.org/info/data/?content-type=application/json' | python -c 'import json,sys;print json.loads(sys.stdin.read())["releases"][0];'`
mysql -h useastdb.ensembl.org -u anonymous -e 'show databases like "%core_'$BUILD'_%";' |sed 1d > ensembl_databases.txt

getdataset(){
	DB=$1
	NAME=`echo $DB | sed 's/_core_[0-9_].*//'`

	mysql -h useastdb.ensembl.org -u anonymous -e "SELECT stable_id FROM $DB.gene; SELECT stable_id FROM $DB.transcript; SELECT stable_id FROM $DB.translation; SELECT meta_value as stable_id FROM $DB.meta WHERE meta_key=\"species.display_name\";" > $NAME.data
	split -p stable_id "$NAME.data" "$NAME."

	STAMP=`TZ=UTC date "+%FT%T"`

	##label=`echo $NAME | tr _ ' '`
	##label="$(tr '[:lower:]' '[:upper:]' <<< ${label:0:1})${label:1}"
	label=`tail -n1 $NAME.ad`

	echo import -d "\"$STAMP\"" -s "\"$label\"" index org.ensembl.gene ${NAME}_gene.txt
	echo import -d "\"$STAMP\"" -s "\"$label\"" index org.ensembl.transcript ${NAME}_transcript.txt
	echo import -d "\"$STAMP\"" -s "\"$label\"" index org.ensembl.protein ${NAME}_protein.txt

	rm $NAME.ad
}

cat ensembl_databases.txt | while read X; do getdataset "$X"; done

rename .ab _transcript.txt *.ab
rename .ac _protein.txt *.ac
rename .aa _gene.txt *.aa
rm *.data

echo import new org.ensembl.gene "\"Ensembl Gene ID\""
echo import urls org.ensembl.gene "\"https://ensembl.org\"" "\"https://www.ensembl.org/id/%s\""
echo import ref org.ensembl.gene ensembl.ris

echo import new org.ensembl.protein "\"Ensembl Protein ID\""
echo import urls org.ensembl.protein "\"https://ensembl.org\"" "\"https://www.ensembl.org/id/%s\""
echo import ref org.ensembl.protein ensembl.ris

echo import new org.ensembl.transcript "\"Ensembl Transcript ID\""
echo import urls org.ensembl.transcript "\"https://ensembl.org\"" "\"https://www.ensembl.org/id/%s\""
echo import ref org.ensembl.transcript ensembl.ris
