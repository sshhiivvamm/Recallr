// Basic JavaScript Code

// 1. Variables
const name = "Shivam";
let age = 22;

// 2. Function
function greet(name) {
  return `Hello, ${name}! Welcome to JavaScript.`;
}

// 3. Array
const fruits = ["Apple", "Banana", "Mango"];

// 4. Loop
console.log("=== Fruits List ===");
fruits.forEach((fruit, index) => {
  console.log(`${index + 1}. ${fruit}`);
});

// 5. Greeting
console.log("\n=== Greeting ===");
console.log(greet(name));

// 6. Simple Math
console.log("\n=== Math ===");
console.log(`2 + 3 = ${2 + 3}`);
console.log(`10 * 5 = ${10 * 5}`);
console.log(`Age next year = ${age + 1}`);
