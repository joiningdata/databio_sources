STAMP=`TZ=UTC date "+%FT%T"`
curl -o hgnc.tsv 'https://www.genenames.org/cgi-bin/download/custom?col=gd_hgnc_id&col=gd_app_sym&col=gd_app_name&col=gd_pub_acc_ids&col=gd_pub_refseq_ids&col=gd_enz_ids&col=gd_pub_eg_id&col=gd_pub_ensembl_id&col=gd_mgd_id&col=gd_other_ids_list&status=Approved&hgnc_dbtag=on&order_by=gd_app_sym_sort&format=text&submit=submit'

curl -LO ftp://ftp.expasy.org/databases/enzyme/enzyme.dat
echo ec_number >ec_numbers.txt
grep '^ID' enzyme.dat |cut -c 6- >> ec_numbers.txt

cut -f1 hgnc.tsv >hgnc_ids.txt
cut -f2 hgnc.tsv >hgnc_symbols.txt
cut -f3 hgnc.tsv >hgnc_names.txt
# 4: Accession numbers = GenBank (ignored)
#cut -f5 hgnc.tsv | sed $'s/, /\\\n/g' | grep -v '^$' |sort -ur >hgnc_refseq.txt
#cut -f6 hgnc.tsv | sed $'s/, /\\\n/g' | grep -v '^$' |sort -ur >hgnc_ec.txt

# all should be loaded already
##cut -f7 hgnc.tsv | grep -v '^$' >hgnc_ncbigene.txt
##cut -f8 hgnc.tsv | grep -v '^$' >hgnc_ensgene.txt

echo import -d "\"$STAMP\"" index org.genenames.gene hgnc_ids.txt
echo import -d "\"$STAMP\"" index org.genenames.symbol hgnc_symbols.txt
echo import -d "\"$STAMP\"" index org.genenames.name hgnc_names.txt
echo import -d "\"$STAMP\"" -s "\"HGNC Linked\"" index uk.ac.qmul.iubmb.enzyme ec_numbers.txt

cut -f1,2 hgnc.tsv >hgnc_id2hgnc_symbol.tsv
cut -f1,3 hgnc.tsv >hgnc_id2hgnc_name.tsv
cut -f2,3 hgnc.tsv >hgnc_symbol2hgnc_name.tsv

cut -f1,5 hgnc.tsv | awk -F $'\t' '{split($2, X, ", "); for( i in X ) { print $1 "\t" X[i];}}' >hgnc_refseq.tsv
cut -f1,6 hgnc.tsv | awk -F $'\t' '{split($2, X, ", "); for( i in X ) { print $1 "\t" X[i];}}' >hgnc_ec.tsv

cut -f1,7 hgnc.tsv | awk -F $'\t' '{split($2, X, ", "); for( i in X ) { print $1 "\t" X[i];}}'  >hgnc_id2ncbi_gene.tsv
cut -f1,8 hgnc.tsv | awk -F $'\t' '{split($2, X, ", "); for( i in X ) { print $1 "\t" X[i];}}'  >hgnc_id2ensembl_gene.tsv


# record metadata
echo import new org.genenames.gene "HGNC Gene ID"
echo import new org.genenames.symbol "HGNC Gene Symbol"
echo import new org.genenames.name "HGNC Gene Name"

echo import urls org.genenames.gene "\"http://www.genenames.org/\"" "\"http://www.genenames.org/cgi-bin/gene_symbol_report?hgnc_id=%s\""
echo import urls org.genenames.symbol "\"http://www.genenames.org/\"" "\"https://www.genenames.org/tools/search/#!/all?query=%s\""
echo import urls org.genenames.name "\"http://www.genenames.org/\"" "\"https://www.genenames.org/tools/search/#!/all?query=%s\""

echo import ref org.genenames.gene hgnc.ris
echo import ref org.genenames.symbol hgnc.ris
echo import ref org.genenames.name hgnc.ris

echo import new uk.ac.qmul.iubmb.enzyme "\"Enzyme Classification (EC)\""
echo import urls uk.ac.qmul.iubmb.enzyme "\"https://www.qmul.ac.uk/sbcs/iubmb/enzyme/\"" "\"https://enzyme.expasy.org/EC/%s\""
echo import ref uk.ac.qmul.iubmb.enzyme ec.ris




echo import -d "\"$STAMP\"" map org.genenames.gene org.genenames.symbol hgnc_id2hgnc_symbol.tsv
echo import -d "\"$STAMP\"" map org.genenames.gene org.genenames.name hgnc_id2hgnc_name.tsv
echo import -d "\"$STAMP\"" map org.genenames.symbol org.genenames.name hgnc_symbol2hgnc_name.tsv

echo import -d "\"$STAMP\"" map org.genenames.gene gov.nih.nlm.ncbi.gene hgnc_id2ncbi_gene.tsv
echo import -d "\"$STAMP\"" map org.genenames.gene org.ensembl.gene hgnc_id2ensembl_gene.tsv

echo import -d "\"$STAMP\"" map org.genenames.gene gov.nih.nlm.ncbi.refseq_transcript hgnc_refseq.tsv
echo import -d "\"$STAMP\"" map org.genenames.gene uk.ac.qmul.iubmb.enzyme hgnc_ec.tsv
