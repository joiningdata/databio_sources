
handleOrg() {
	org=$1
	orgName=`grep $'^'$org$'\t' orgs.txt|cut -f2`
	STAMP=`TZ=UTC date "+%FT%T"`

	echo "kegg_gene_id" > kegg_genes_${org}.txt
	curl -sL http://rest.kegg.jp/list/$org |cut -f 1 >> kegg_genes_${org}.txt
	curl -sL http://rest.kegg.jp/conv/$org/ncbi-geneid | sed 's/ncbi-geneid://' >> ncbi_gene2kegg_gene.tsv
	curl -sL http://rest.kegg.jp/conv/$org/uniprot | sed 's/up://' >> uniprot2kegg_gene.tsv

	echo $STAMP kegg_genes_${org}.txt >&2
	wc -l kegg_genes_${org}.txt >&2

	echo import -d "\"$STAMP\"" -s "\"$orgName\"" index jp.kegg.gene kegg_genes_${org}.txt
}

STAMP=`TZ=UTC date "+%FT%T"`
#### get list of organism codes from here:
## also WTF lots of duplicate names
curl -sL http://rest.kegg.jp/list/organism |cut -f2,3 | \
	awk -F'\t' '{ org[$1] = $2; seen[$2]++ } END { for (i in org) { if (seen[org[i]] > 1) { printf("%s\t%s (%s)\n", i, org[i], i) } else { printf("%s\t%s\n", i, org[i]) } } }' > orgs.txt
wc -l orgs.txt >&2

echo $'entrez_gene_id\tkegg_gene_id' >ncbi_gene2kegg_gene.tsv
echo $'uniprot_id\tkegg_gene_id' >uniprot2kegg_gene.tsv

cut -f1 orgs.txt | while read tax; do handleOrg $tax; done

# record metadata
echo import new jp.kegg.gene "\"KEGG Gene ID\""
echo import urls jp.kegg.gene "\"https://kegg.jp\"" "\"https://www.genome.jp/dbget-bin/www_bget?%s\""
echo import ref jp.kegg.gene kegg.ris

#############################################
# download and extract the current data

cut -f1 uniprot2kegg_gene.tsv >uniprot_accessions.txt

# collect all kegg gene ids into one file
echo "kegg_gene_id" > kegg_genes_all.tsv
grep -h -v 'kegg_gene_id' kegg_genes_*.txt >> kegg_genes_all.tsv

echo import -d \""$STAMP\"" index jp.kegg.gene kegg_genes_all.tsv

echo import -d \""$STAMP\"" -s "\"KEGG Linked\"" index org.uniprot.acc uniprot_accessions.txt

echo import -d \""$STAMP\"" map gov.nih.nlm.ncbi.gene jp.kegg.gene ncbi_gene2kegg_gene.tsv
echo import -d \""$STAMP\"" map org.uniprot.acc jp.kegg.gene uniprot2kegg_gene.tsv
