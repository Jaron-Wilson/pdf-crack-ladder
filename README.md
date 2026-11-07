# pdf-crack-ladder

A GPU password-recovery ladder for PDFs. Give it a password-protected PDF **you own or are
authorized to open**, and it recovers a forgotten password by guessing millions of candidates per
second with [hashcat](https://hashcat.net/hashcat/) — starting with the guesses that pay off first
and only falling back to slower brute force if those miss.

It's a thin, readable wrapper around two standard tools (John the Ripper's `pdf2john` and hashcat).
The value is the **ladder**: the order of attacks, with time caps and an auto-stop, so you spend GPU
time where real passwords actually live instead of brute-forcing from `aaaa`.

> Use this only on documents you own or have explicit permission to access — recovering your own
> forgotten password, authorized security testing, or a CTF. That's what it's for.

## How it works

A protected PDF doesn't store your password. It stores the result of running the password through a
one-way function (a hash) and derives the encryption key from that. You can't reverse it. So you
don't "unlock" the file — you **guess a password, run the guess through the same function, and check
whether it produces the right key.** When a guess matches, that guess *is* the password.

Two steps:

1. **Extract the hash** with `pdf2john`. You get one line starting with `$pdf$...` holding the
   encryption parameters, salt, and a check value. An example is in
   [`examples/sample-10500.hash`](examples/sample-10500.hash).
2. **Guess, on the GPU**, with hashcat in mode `-m 10500`. A pair of GTX 1080s does roughly
   **24 million guesses/second** against a PDF hash.

### Where `rockyou` comes in

`rockyou.txt` is ~14 million **real** passwords from the 2009 RockYou breach. Because they're
passwords people actually chose, trying them — and small mutations of them — beats blind brute force
by a mile. Most human passwords are a word with a predictable tweak, and that's exactly what a
wordlist plus a **rules file** covers: a rule mutates each word (`sunshine` → `Sunshine`,
`sunshine1`, `sunshine!`, `5unshine`, …), so 14 million base words become hundreds of millions of
realistic guesses.

In practice a human-chosen PDF password falls in the first couple of rungs in seconds.

## The ladder

`crack.sh` / `crack.ps1` run these in order and stop the instant one hits:

| # | Stage | Why it's here |
|---|---|---|
| 1 | `rockyou` straight | real passwords, as-is |
| 2 | `rockyou` + `top10_2025` rules | the common human tweaks — highest yield for the time |
| 3 | `rockyou` + `rockyou-30000` rules | a much bigger mutation set |
| 4 | statistical masks (`rockyou-1-60`) | brute force **ordered** by real character patterns |
| 5 | combinator (word + word) | `sunflowerred`, `redhouse`, … |
| 6-10 | plain brute force, growing length | digits, lowercase, lower+digit, long digits, all-chars — time-capped |
| 11-12 | big rule files (`d3ad0ne`, `dive`) | the long tail, left for last |

Each stage after the wordlist is time-capped (`--runtime`) so a slow rung can't starve the rest, and
the whole thing exits as soon as `FOUND.txt` is written.

## Quick start

```bash
# 1. tools: hashcat (https://hashcat.net/hashcat/) and John the Ripper (for pdf2john)
# 2. wordlists:
scripts/setup.sh                         # downloads rockyou.txt + a 100k slice

# 3. extract the hash from your PDF:
scripts/extract-hash.sh my-locked.pdf > work/hash.txt

# 4. run the ladder (from inside your hashcat folder, so its rules/ and masks/ resolve):
scripts/crack.sh work/hash.txt
scripts/ctl.sh watch                     # follow progress; ctl.sh status / stop
```

Windows is identical with the `.ps1` scripts:

```powershell
scripts\extract-hash.ps1 -Pdf my-locked.pdf > work\hash.txt
powershell -ExecutionPolicy Bypass -File scripts\crack.ps1 -Hash work\hash.txt
scripts\ctl.ps1 watch
```

`rules/` and `masks/` (top10_2025, d3ad0ne, dive, `rockyou-*.hcmask`) ship **with hashcat** — run the
cracker from inside the hashcat directory, or copy those two folders next to your hash.

## Which hashcat mode?

`-m 10500` covers most PDFs (Acrobat 1.4–1.6, 128-bit RC4/AES). Newer encryption needs a different
mode — the `$pdf$` prefix tells you, and `pdf2john` sets it:

| PDF encryption | hashcat `-m` |
|---|---|
| PDF 1.4 – 1.6 (Acrobat 5–8) | `10500` |
| PDF 1.7 L3 (Acrobat 9) | `10600` |
| PDF 1.7 L8 (Acrobat 10/11, AES-256) | `10700` |

Pass a different one with `-Mode` (PowerShell) or `MODE=10700 scripts/crack.sh ...` (bash).

## The takeaway for choosing passwords

This is why a short word-plus-number dies in seconds and a long random passphrase doesn't. Wordlists
and rules devour human-chosen passwords; they can't keep up with **length and randomness**. Four
random words, or 16+ random characters, push you off the ladder entirely.

## Credits

- [hashcat](https://hashcat.net/hashcat/) — the engine, plus the bundled rules and masks.
- [John the Ripper](https://www.openwall.com/john/) — `pdf2john` hash extraction.
- `rockyou.txt` — the 2009 RockYou breach corpus, the standard first-pass wordlist.
- Example format in `examples/` is a shape reference; get a real working one with `hashcat -m 10500 --example-hashes`.
