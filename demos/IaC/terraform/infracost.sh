export dest_path="infracost_base.json"

if [ -f "$dest_path" ]; then
      echo "base file already exists at $dest_path"
      infracost breakdown --path . --terraform-var-file deploydev.tfvars --format json --out-file infracost_new.json
      infracost diff --path . --terraform-var-file deploydev.tfvars --compare-to infracost_base.json  --out-file infracost_compare.json --show-skipped

      # infracost output --path infracost_compare.json --format html --out-file infracostreport.# html
      # infracost output --path infracost_compare.json --format table
      # infracost output --path infracost_base.json --format diff
  else
      echo "Its not there $dest_path"
      infracost breakdown --path . --terraform-var-file deploydev.tfvars --format json --out-file infracost_base.json

      infracost output --path infracost_base.json --format html --out-file infracostreport.html
      infracost output --path infracost_base.json --format table
fi
