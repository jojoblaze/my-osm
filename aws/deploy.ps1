# Create the stack with AWS cloud formation

aws cloudformation create-stack --stack-name osm --template-body file://./osm-cloud-formation.template --parameters file://./osm-stack-params.json --disable-rollback