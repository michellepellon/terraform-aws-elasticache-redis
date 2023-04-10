fmt:
	terraform fmt

init:
	terraform init

validate:
	terraform validate

plan:
	terraform plan

apply:
	terraform apply -auto-approve

docs:
	terraform-docs markdown ./

test: validate
	tflint .
	checkov --directory .

cost:
	infracost breakdown --path .
