#!/bin/bash
cat > /tmp/test_loc.sh << 'SCRIPT'
#!/bin/bash
find "\$1" -name "*.py" | while read f; do
    loc=$(grep -v -E '^\s*(#|$)' "\$f" | wc -l)
    echo "\$f: \$loc"
done
SCRIPT
chmod +x /tmp/test_loc.sh
/tmp/test_loc.sh /home/reeinharrrd/projects/personal/dotfiles | head -5
echo "Script works!"
