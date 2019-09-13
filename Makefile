all: tools db data-omim data-hgnc data-ncbi data-ensembl data-uniprot data-kegg

tools:
	go build -o import github.com/joiningdata/databio/cmd/import

db:
	./import init

data-ensembl:
	cp sources.sqlite ensembl/
	cd ensembl; \
	time bash import_ensembl.sh |sed 's/^import/..\/import/' > doimport.sh; \
	time bash doimport.sh && mv sources.sqlite ..
	
data-hgnc:
	cp sources.sqlite hgnc/
	cd hgnc; \
	time bash import_hgnc.sh |sed 's/^import/..\/import/' > doimport.sh; \
	time bash doimport.sh && mv sources.sqlite ..

data-ncbi:
	cp sources.sqlite ncbi/
	cd ncbi; \
	time bash import_ncbi.sh |sed 's/^import/..\/import/' > doimport.sh; \
	time bash doimport.sh && mv sources.sqlite ..

data-omim:
	cp sources.sqlite omim/
	cd omim; \
	time bash import_omim.sh |sed 's/^import/..\/import/' > doimport.sh; \
	time bash doimport.sh && mv sources.sqlite ..

data-uniprot:
	cp sources.sqlite uniprot/
	cd uniprot; \
	time bash import_uniprot.sh |sed 's/^import/..\/import/' > doimport.sh; \
	time bash doimport.sh && mv sources.sqlite ..

data-kegg:
	cp sources.sqlite kegg/
	cd kegg; \
	time bash import_kegg.sh |sed 's/^import/..\/import/' > doimport.sh; \
	time bash doimport.sh && mv sources.sqlite ..
