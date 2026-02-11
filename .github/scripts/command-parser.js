const body = process.argv[2] || "";

const commands = {
  build: body.includes("/build") || body.includes("/all"),
  lint: body.includes("/lint") || body.includes("/all"),
  fix: body.includes("/fix") || body.includes("/all"),
  refactor: body.includes("/refactor") || body.includes("/all"),
  merge: body.includes("/merge") || body.includes("/all"),
  ai: body.includes("/ai") || body.includes("/all"),
};

for (const [key, value] of Object.entries(commands)) {
  console.log(`::set-output name=${key}::${value}`);
}