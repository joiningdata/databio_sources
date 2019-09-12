# less than 5s for end-to-end loading

#############################################
# download and extract the current data

STAMP=`TZ=UTC date "+%FT%T"`
curl -LO https://omim.org/static/omim/data/mim2gene.txt

echo "mim_number" > omim_phenotypes.txt
grep 'phenotype' mim2gene.txt |grep -v '^#' | cut -f1  >>omim_phenotypes.txt

# keep only the header and gene records listed
echo $'mim_number\tmim_type\tentrez_gene_id\tsymbol\tensembl_gene_id' > mim2gene.genes.txt
grep -v '^#' mim2gene.txt |grep gene >>mim2gene.genes.txt

cut -f1 mim2gene.genes.txt >omim_genes.txt

cut -f1,3 mim2gene.genes.txt |grep -v '\t$' >omim_gene2ncbi_gene.tsv
cut -f1,5 mim2gene.genes.txt |grep -v '\t$' >omim_gene2ensembl_gene.tsv

#############################################

# record metadata
echo import -t integer new org.omim.gene "\"OMIM Gene ID\""
echo import urls org.omim.gene "\"https://omim.org\"" "\"http://omim.org/entry/%s\""
echo import ref org.omim.gene omim.ris

echo import -t integer new org.omim.phenotype "\"OMIM Phenotype ID\""
echo import urls org.omim.phenotype "\"https://omim.org\"" "\"http://omim.org/entry/%s\""
echo import ref org.omim.phenotype omim.ris

# load the index data and source mappings
echo import -d "\"$STAMP\"" index org.omim.gene omim_genes.txt
echo import -d "\"$STAMP\"" index org.omim.phenotype omim_phenotypes.txt

echo import -d "\"$STAMP\"" map org.omim.gene gov.nih.nlm.ncbi.gene omim_gene2ncbi_gene.tsv
echo import -d "\"$STAMP\"" map org.omim.gene org.ensembl.gene omim_gene2ensembl_gene.tsv
