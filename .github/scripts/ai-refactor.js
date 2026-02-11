const fs = require("fs");

console.log("AI refactor layer running...");

// Contoh sederhana: hapus trailing whitespace
function cleanFile(path) {
  const content = fs.readFileSync(path, "utf8");
  const cleaned = content.replace(/[ \t]+$/gm, "");
  fs.writeFileSync(path, cleaned);
}

function walk(dir) {
  fs.readdirSync(dir).forEach(file => {
    const full = dir + "/" + file;
    if (fs.statSync(full).isDirectory()) {
      walk(full);
    } else if (full.endsWith(".kt")) {
      cleanFile(full);
    }
  });
}

walk("app");