const fs = require('fs');

const content = fs.readFileSync('src/config/constants.js', 'utf8');

// Fix patterns like בית חג"י -> בית חג\"י (already correct)
// Fix patterns like דוב'\ב -> דוב''ב (double single quotes)
// Fix patterns like ניר ח'\ן -> ניר ח''ן

// Find and replace backslash followed by Hebrew letter
let fixed = content;

// List of specific replacements needed based on the lint errors
const replacements = [
  ["'בית חג\\\"י'", "'בית חג\\\"י'"], // This is already correct
  ["'דוב\\'\\ב'", "'דוב\\'\\'ב'"],
  ["'יד רמב\\'\\ם'", "'יד רמב\\'\\'ם'"],
  ["'ייט\\'\\ב'", "'ייט\\'\\'ב'"],
  ["'כפר ביל\\'\\ו'", "'כפר ביל\\'\\'ו'"],
  ["'כפר חב\\'\\ד'", "'כפר חב\\'\\'ד'"],
  ["'כפר הרא\\'\\ה'", "'כפר הרא\\'\\'ה'"],
  ["'כפר הרי\\'\\ף וצומת ראם'", "'כפר הרי\\'\\'ף וצומת ראם'"],
  ["'כפר מל\\'\\ל'", "'כפר מל\\'\\'ל'"],
  ["'כרם מהר\\'\\ל'", "'כרם מהר\\'\\'ל'"],
  ["'מצפה אבי\\'\\ב'", "'מצפה אבי\\'\\'ב'"],
  ["'מרכז מיר\\'\\ב'", "'מרכז מיר\\'\\'ב'"],
  ["'נווה אטי\\'\\ב'", "'נווה אטי\\'\\'ב'"],
  ["'ניר ח\\'\\ן'", "'ניר ח\\'\\'ן'"],
  ["'נתיב הל\\'\\ה'", "'נתיב הל\\'\\'ה'"],
  ["'עין הנצי\\'\\ב'", "'עין הנצי\\'\\'ב'"],
  ["'פעמי תש\\'\\ז'", "'פעמי תש\\'\\'ז'"],
  ["'תלמי ביל\\'\\ו'", "'תלמי ביל\\'\\'ו'"],
];

replacements.forEach(([from, to]) => {
  if (fixed.includes(from)) {
    fixed = fixed.replace(from, to);
    console.log(`Fixed: ${from} -> ${to}`);
  } else {
    console.log(`Not found: ${from}`);
  }
});

fs.writeFileSync('src/config/constants.js', fixed, 'utf8');
console.log('\nDone!');