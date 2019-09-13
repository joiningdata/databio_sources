BUILD=`curl -sL 'https://rest.ensembl.org/info/data/?content-type=application/json' | python -c 'import json,sys;print json.loads(sys.stdin.read())["releases"][0];'`
mysql -h useastdb.ensembl.org -u anonymous -e 'show databases like "%core_'$BUILD'_%";' |sed 1d > ensembl_databases.txt

QUERIES=$(cat <<- ENDSQL
	SELECT stable_id FROM gene;
	SELECT stable_id FROM transcript;
	SELECT stable_id FROM translation;
	SELECT meta_value as stable_id FROM meta WHERE meta_key="species.display_name";
	SELECT g.stable_id, t.stable_id AS transcript_id
	  FROM gene g, transcript t
	 WHERE g.gene_id=t.gene_id AND t.canonical_translation_id is null;
	SELECT g.stable_id, t.stable_id AS transcript_id, p.stable_id AS protein_id
	  FROM gene g, transcript t, translation p
	 WHERE g.gene_id=t.gene_id AND t.canonical_translation_id=p.translation_id;
ENDSQL
)

getdataset(){
	DB=$1
	NAME=`echo $DB | sed 's/_core_[0-9_].*//'`

	STAMP=`TZ=UTC date "+%FT%T"`
	mysql -h useastdb.ensembl.org -u anonymous -e "$QUERIES" "$DB" > $NAME.data
	split -p stable_id "$NAME.data" "$NAME."

	mv "${NAME}.aa" "${NAME}_gene.txt"
	mv "${NAME}.ab" "${NAME}_transcript.txt"
	mv "${NAME}.ac" "${NAME}_protein.txt"
	label=`tail -n1 $NAME.ad`
	mv "${NAME}.ae" "${NAME}_gene2transcript.tsv"
	cut -f 1,2 "${NAME}.af" |sed 1d >> "${NAME}_gene2transcript.tsv"
	cut -f 2,3 "${NAME}.af" > "${NAME}_transcript2protein.tsv"

	rm ${NAME}.data ${NAME}.ad ${NAME}.af

	echo import -d "\"$STAMP\"" -s "\"$label\"" index org.ensembl.gene ${NAME}_gene.txt
	echo import -d "\"$STAMP\"" -s "\"$label\"" index org.ensembl.transcript ${NAME}_transcript.txt
	echo import -d "\"$STAMP\"" -s "\"$label\"" index org.ensembl.protein ${NAME}_protein.txt
}

cat ensembl_databases.txt | while read X; do getdataset "$X"; done

echo import new org.ensembl.gene "\"Ensembl Gene ID\""
echo import urls org.ensembl.gene "\"https://ensembl.org\"" "\"https://www.ensembl.org/id/%s\""
echo import ref org.ensembl.gene ensembl.ris

echo import new org.ensembl.protein "\"Ensembl Protein ID\""
echo import urls org.ensembl.protein "\"https://ensembl.org\"" "\"https://www.ensembl.org/id/%s\""
echo import ref org.ensembl.protein ensembl.ris

echo import new org.ensembl.transcript "\"Ensembl Transcript ID\""
echo import urls org.ensembl.transcript "\"https://ensembl.org\"" "\"https://www.ensembl.org/id/%s\""
echo import ref org.ensembl.transcript ensembl.ris

echo $'gene_id\ttranscript_id' >all.gene2transcript.tsv
echo $'transcript_id\tprotein_id' >all.transcript2protein.tsv

cat *_gene2transcript.tsv |sed '/transcript_id/ d' >>all.gene2transcript.tsv
cat *_transcript2protein.tsv |sed '/transcript_id/ d' >>all.transcript2protein.tsv

STAMP=`TZ=UTC date -r ensembl_databases.txt "+%FT%T"`
echo import -d "\"$STAMP\"" map org.ensembl.gene org.ensembl.transcript all.gene2transcript.tsv
echo import -d "\"$STAMP\"" map org.ensembl.transcript org.ensembl.protein all.transcript2protein.tsv