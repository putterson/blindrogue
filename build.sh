set +x #Robust errors

# Clean the bin/ folder
rm -rf bin/ && mkdir -p bin/

cp src/*.html bin/
# Copy javascript
#for file in src/*.js ; do
#    cp "$file" bin/
#done
# Compile coffeescript
for file in src/*.coffee ; do
    coffee -o bin/ "$file"
done

# Copy dependencies (javascript)
for file in deps/*.js ; do
    cp "$file" bin/
done

cd bin
node noderun.js
