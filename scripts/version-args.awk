# Each marker binds the following Docker ARG to one exported catalog variable.
# In "args" mode emit arguments for Docker. In "defaults" mode refresh the file.
/^# versions\.env: [A-Z0-9_]+\r?$/ {
    key = $3
    sub(/\r$/, "", key)
    if (mode == "defaults") print
    if ((getline) <= 0 || $0 !~ /^ARG [A-Z0-9_]+(=|\r?$)/ || ENVIRON[key] == "") {
        print FILENAME ":" FNR ": invalid version binding for " key > "/dev/stderr"
        exit 1
    }
    current = $0
    sub(/\r$/, "", current)
    declaration = substr(current, 5)
    name = declaration
    sub(/=.*/, "", name)
    value = name "=" ENVIRON[key]
    has_default = declaration != name
    if (check_defaults && has_default && declaration != value) {
        printf "%s:%d: needs sync for %s in versions.env\n  found:    %s\n  expected: ARG %s\n", FILENAME, FNR, key, current, value > "/dev/stderr"
        drift = 1
    }
    if (mode == "defaults") {
        if (has_default) print "ARG " value ($0 ~ /\r$/ ? "\r" : "")
        else print
    } else if (!seen[name]++) {
        print value
    }
    bindings++
    next
}
mode == "defaults" { print }
END {
    if (!bindings) {
        print FILENAME ": no version bindings" > "/dev/stderr"
        exit 1
    }
    if (drift) exit 1
}
