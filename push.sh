env PREFIX='./dist' `npm bin`/grunt build
tar cvzf app.tar.gz -C dist .
curl -F "app=fhirface" -F "file=@./app.tar.gz;filename=file" http://try-fhirplace.hospital-systems.com/api/app
rm -rf app.tar.gz
