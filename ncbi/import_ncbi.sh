# approx 12 mins end-to-end for import.

handleSubset() {
	filename=$1
	subsetName=`basename "$filename" gene_info.gz|sed 's/All_Data.//'|sed 's/All_//'`
	STAMP=`TZ=UTC date -r "$filename" "+%FT%T"`

	echo $STAMP $filename >&2
	gunzip -c "$filename" |cut -f2 >ncbi_gene.${subsetName}txt
	wc -l ncbi_gene.${subsetName}txt >&2

	label=`echo $subsetName |tr _ ' '|sed 's/\.$//'`
	echo import -d "\"$STAMP\"" -s "\"$label\"" index gov.nih.nlm.ncbi.gene ncbi_gene.${subsetName}txt
}

handleMapping() {
	cols=$1
	ofn=$2

	cut -f $1 gene2ensembl |grep -v -- '-$' > "$ofn"
	wc -l "$ofn" >&2
}

# get a LOT of gene data and subsets
rsync -avzP ftp.ncbi.nlm.nih.gov::gene/DATA/GENE_INFO/ ./ >&2

find . -name "*gene_info.gz" | while read fn; do handleSubset "$fn"; done

STAMP=`TZ=UTC date "+%FT%T"`
curl -LO ftp://ftp.ncbi.nih.gov/gene/DATA/gene2ensembl.gz

## this file contains the Ensembl versions used for mapping above
#curl -LO ftp://ftp.ncbi.nlm.nih.gov/gene/DATA/README_ensembl

#############################################
# download and extract the current data

echo $STAMP gene2ensembl.gz >&2

gunzip -c gene2ensembl.gz > gene2ensembl

handleMapping 2,3 ncbi_gene2ensembl_gene.tsv
handleMapping 3,4 ensembl_gene2refseq_transcript.tsv

handleMapping 2,4 ncbi_gene2refseq_transcript.tsv
handleMapping 2,5 ncbi_gene2ensembl_transcript.tsv
handleMapping 4,5 refseq_transcript2ensembl_transcript.tsv

handleMapping 2,6 ncbi_gene2refseq_protein.tsv
handleMapping 2,7 ncbi_gene2ensembl_protein.tsv
handleMapping 6,7 refseq_protein2ensembl_protein.tsv



# load the source mappings (ncbi gene/refseq -> others)

echo import -d "\"$STAMP\"" map gov.nih.nlm.ncbi.gene org.ensembl.gene	ncbi_gene2ensembl_gene.tsv
echo import -d "\"$STAMP\"" map gov.nih.nlm.ncbi.gene org.ensembl.protein	ncbi_gene2ensembl_protein.tsv
echo import -d "\"$STAMP\"" map gov.nih.nlm.ncbi.gene org.ensembl.transcript	ncbi_gene2ensembl_transcript.tsv
echo import -d "\"$STAMP\"" map gov.nih.nlm.ncbi.gene gov.nih.nlm.ncbi.refseq_protein		ncbi_gene2refseq_protein.tsv
echo import -d "\"$STAMP\"" map gov.nih.nlm.ncbi.gene gov.nih.nlm.ncbi.refseq_transcript	ncbi_gene2refseq_transcript.tsv

echo import -d "\"$STAMP\"" map org.ensembl.gene gov.nih.nlm.ncbi.refseq_transcript	ensembl_gene2refseq_transcript.tsv

echo import -d "\"$STAMP\"" map gov.nih.nlm.ncbi.refseq_protein org.ensembl.protein	refseq_protein2ensembl_protein.tsv
echo import -d "\"$STAMP\"" map gov.nih.nlm.ncbi.refseq_transcript org.ensembl.transcript	refseq_transcript2ensembl_transcript.tsv

# record metadata
echo import -t integer new gov.nih.nlm.ncbi.gene "\"NCBI Entrez Gene ID\""
echo import new gov.nih.nlm.ncbi.refseq_protein "\"RefSeq Protein ID\""
echo import new gov.nih.nlm.ncbi.refseq_transcript "\"RefSeq Transcript ID\""

echo import urls gov.nih.nlm.ncbi.gene "\"https://www.ncbi.nlm.nih.gov/gene\"" "\"https://www.ncbi.nlm.nih.gov/gene/%s\""
echo import urls gov.nih.nlm.ncbi.refseq_protein "\"https://www.ncbi.nlm.nih.gov/protein\"" "\"https://www.ncbi.nlm.nih.gov/protein/%s\""
echo import urls gov.nih.nlm.ncbi.refseq_transcript "\"https://www.ncbi.nlm.nih.gov/nuccore\"" "\"https://www.ncbi.nlm.nih.gov/nuccore/%s\""

echo import new org.uniprot.acc "\"UniprotKB Accession\""
echo import urls org.uniprot.acc "\"https://uniprot.org\"" "\"https://www.uniprot.org/uniprot/%s\""

#STAMP=`TZ=UTC date -r gene_refseq_uniprotkb_collab.gz "+%FT%T"`
STAMP=`TZ=UTC date "+%FT%T"`
curl -LO ftp://ftp.ncbi.nlm.nih.gov/refseq/uniprotkb/gene_refseq_uniprotkb_collab.gz
gunzip -c gene_refseq_uniprotkb_collab.gz > refseq_protein2uniprot.tsv
echo import -d "\"$STAMP\"" map gov.nih.nlm.ncbi.refseq_protein org.uniprot.acc refseq_protein2uniprot.tsv

echo import ref gov.nih.nlm.ncbi.gene entrez.ris
echo import ref gov.nih.nlm.ncbi.refseq_protein refseq.ris
echo import ref gov.nih.nlm.ncbi.refseq_transcript refseq.ris

cut -f1 refseq_protein2*.tsv >refseq_protein1.txt
cut -f2 *2refseq_protein.tsv | sort -u - refseq_protein1.txt | fgrep -v protein_accession.version > refseq_proteins.txt
rm refseq_protein1.txt

cut -f1 refseq_transcript2*.tsv >refseq_transcript1.txt
cut -f2 *2refseq_transcript.tsv | sort -u - refseq_transcript1.txt >refseq_transcript2.txt
echo RNA_nucleotide_accession.version > refseq_transcripts.txt
fgrep -v RNA_nucleotide_accession.version refseq_transcript2.txt >> refseq_transcripts.txt
rm refseq_transcript1.txt refseq_transcript2.txt

echo import -d "\"$STAMP\"" -s "\"Entrez Gene Linked\"" index gov.nih.nlm.ncbi.refseq_protein refseq_proteins.txt
echo import -d "\"$STAMP\"" -s "\"Entrez Gene Linked\"" index gov.nih.nlm.ncbi.refseq_transcript refseq_transcripts.txt
