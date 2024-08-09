# bnm-flex-test

# Build

gcloud dataflow flex-template build gs://zr-dev-vincegonzalez/wordcount-flex-template-py.json  \
	--image-gcr-path "us-east4-docker.pkg.dev/zr-dev-vincegonzalez/vincegonzalez/wordcount-flex-template-python:latest"  \
	--sdk-language "PYTHON"  \
	--flex-template-base-image "PYTHON3"  \
	--metadata-file "metadata.json"  \
	--py-path "."  \
	--env "FLEX_TEMPLATE_PYTHON_PY_FILE=src/wordcount_flex_template.py"  \
	--env "FLEX_TEMPLATE_PYTHON_REQUIREMENTS_FILE=requirements.txt"

gcloud dataflow flex-template run "wordcount-`date +%Y%m%d-%H%M%S`"  \
	--template-file-gcs-location "gs://zr-dev-vincegonzalez/wordcount-flex-template-py.json"  \
	--parameters input_file_pattern="gs://dataflow-samples/shakespeare/*" \
	--parameters output_file="gs://zr-dev-vincegonzalez/output-"  \
	--region "us-east4" \
	--subnetwork https://www.googleapis.com/compute/v1/projects/zr-dev-vincegonzalez/regions/us-east4/subnetworks/subnet-0 \
	--disable-public-ips

