STAMP=`TZ=UTC date "+%FT%T"`
curl -LO ftp://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/complete/uniprot_sprot.dat.gz
gunzip -c uniprot_sprot.dat.gz | egrep '^(ID|AC|DE|GN|OX|DR|//)' >uniprot.filtered.dat

grep '^AC ' uniprot.filtered.dat |cut -c6- |sed $'s/; */\\\n/g' |grep -v '^$' >uniprot_accessions.txt

echo import new org.uniprot.acc "\"UniprotKB Accession\""
echo import urls org.uniprot.acc "\"https://uniprot.org\"" "\"https://www.uniprot.org/uniprot/%s\""
echo import ref org.uniprot.acc uniprot.ris

echo import -d "\"$STAMP\"" index org.uniprot.acc uniprot_accessions.txt
