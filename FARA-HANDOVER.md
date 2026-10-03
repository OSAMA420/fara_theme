# FA'RA London — Theme Development Handover

Ye document nayi chat shuru karne ke liye hai. Isme wo sab hai jo ab tak
banaya gaya, kaise deploy hota hai, aur kya pending hai.

Aakhri update: 2026-08-24

---

## 1. Setup — buniyadi maloomat

| Cheez | Value |
|---|---|
| Store | `faralondon.myshopify.com` (live domain: `faralondon.com`) |
| **Live theme** | `unsen-v1-9-3-1` — **#144548528304** |
| Dev theme | `Development (98cf40-Fara-Osama)` — #150036283568 (updated 2026-10-03; older dev themes get replaced from time to time — if this ID 404s, run `shopify theme list --store=faralondon.myshopify.com` to find the current `[development]` one) |
| Backup theme | `BACKUP live before feature-highlights 2026-08-07` — #146901926064 |
| Local folder | `Desktop/local_theme_fara` |
| GitHub | `github.com/OSAMA420/fara_theme` (branch `main`) |
| Theme base | T4S / Unsen (vendor theme, ~520 files) |

**Theme ka baap section:** `sections/main-product.liquid` (~4900 lines) — product
page ke saare blocks isi mein hain.

---

## 2. Deploy — sabse ahem hissa

### Rule
**Kabhi bhi `git push` ya live theme deploy karne se pehle Osama se poochna.**
Local edits aur commits bina pooche theek hain — sirf bahar jaane wale steps
(GitHub push, live store) ke liye ijazat chahiye.

### Command

```powershell
.\deploy.ps1 -Message "kya change kiya"
```

`deploy.ps1` repo root mein hai. Ye kabhi bhi plain `shopify theme push` mat
chalana — wo poori theme replace kar deta hai.

### Script kya karta hai

1. Pending local changes commit
2. GitHub se `git pull --rebase`
3. **Live theme se** theme-editor wali files neeche kheenchta hai
   (`config/settings_data.json`, `templates/*.json`) aur commit karta hai
4. GitHub pe push
5. Sirf **badli hui code files** live theme pe push (typed confirmation ke baad)
6. `last-deploy` git tag aage badhata hai — isi se step 5 ko pata chalta hai
   ke kya badla

### Ownership rule (isi se safety aati hai)

- **Repo ki files** → `sections/`, `snippets/`, `assets/`, `layout/`,
  `blocks/`, `locales/` — ye **upar** jati hain
- **Theme editor ki files** → `config/settings_data.json`, `templates/*.json`
  — ye sirf **neeche** aati hain, kabhi upar nahi

**Wajah:** local aur live kaafi drift kar chuke the (~30 template JSON files
alag thin). Plain push se homepage layout aur theme settings wipe ho jate.

### Deploy se pehle hamesha

```bash
shopify theme check --path="." --output=json
```

**Baseline: 138 errors.** Ye sab pehle se maujood hain (app snippets jaise
`ssw-widget-*`, `opinew_*` jo runtime pe inject hote hain, aur theme ka legacy
code). Agar count 138 se **barhe** to kuch naya toota hai.

> `| tail` ke saath mat chalana — exit code `tail` ka aata hai, theme-check ka
> nahi. Isi galti se kaafi der tak "0 errors" dikhta raha tha.

---

## 3. Jo banaya gaya

### Product page ke naye blocks
Sab `sections/main-product.liquid` mein hain. Theme Editor → Product main →
Add block se lagte hain, aur drag karke kahin bhi rakhe ja sakte hain.

| Block | Kya karta hai | Limit |
|---|---|---|
| **Social proof bar** | 3 overlapping faces + naam + blue tick + message | 2 |
| **Notice bar** | Rangeen bar, do line text (English + Urdu) | 2 |
| **Product badges** | Pill badges — icon + text (Formulated In France waghera) | 1 |
| **Comparison image** | "FA'RA vs the rest" jaisi chart image | 1 |
| **Feature highlights** | Heading + 3 icon cards, rangeen background | 1 |

### Nayi section

**Store network** (`sections/store-network.liquid`) — stores ka grid ya moving
row, city buttons se filter hota hai. City pills khud stores se ban-te hain
(duplicate apne aap hat jate hain).

### Purani section mein naya mode

**Logo list** — `Layout design` mein chautha option **"Cards + moving row"**.
Purane teen (Grid / Carousel / Packery) waise ke waise hain.

### Nayi files

```
assets/product-social-proof.css
assets/product-notice.css
assets/product-badges.css
assets/product-comparison-image.css
assets/product-feature-highlights.css
assets/store-network.css
assets/store-network.js          <- marquee + filter ka shared JS
snippets/icon-feature-highlight.liquid    <- 12 preset icons
snippets/icon-product-badge.liquid        <- 9 brand/flag icons
sections/store-network.liquid
deploy.ps1
.gitignore
```

### Doosre fixes

- **Single-variant products pe "Add to cart"** — 5 products pe "Quick Shop"
  aa raha tha kyunki unke single option ka naam custom tha (`Variant: 50 ML`).
  `isDefault` ki logic 14 files mein badli: ab jis product ka sirf 1 variant
  ho use hamesha Add to cart milta hai.
- **Sticky header** — `scroll_header` off kiya (nav ab scroll pe chhupta nahi)
- **Nav text colour** — `clnavst2` white se `#222222` (white-on-white tha)
- **Search box height** — nayi setting `search_h`, 50px se 42px

---

## 4. Metafields — poori list

Sab **Settings → Custom data → Products** mein bante hain.
Type theme ke field se match hona chahiye, warna connect karte waqt list mein
nazar hi nahi aayegi.

| Block | Keys | Type |
|---|---|---|
| **Social proof bar** | `custom.proof_names` | Single line text |
| | `custom.proof_message` | Rich text |
| **Notice bar** | `custom.notice_text` | Rich text |
| | `custom.notice_sub` | Rich text |
| **Product badges** | `custom.badge1_icon` … `custom.badge3_icon` | Single line text |
| | `custom.badge1_text` … `custom.badge3_text` | Single line text |
| **Comparison image** | `custom.compare_chart` | File |
| **Feature highlights** | `custom.fh_bg`, `fh_card_bg`, `fh_icon_bg`, `fh_icon_color`, `fh_heading_color`, `fh_text_color` | Single line text |

### Per-product control ka tareeqa

1. Metafield banao
2. Theme Editor mein block ke field pe **⚡ dynamic source** click karke
   metafield se connect karo
3. **Field khaali chhod do**
4. Jis product ke metafield mein value hogi, sirf wahan block dikhega

**Sab blocks ka rule ek hi hai:** text khaali = block ghayab. Isliye theme
editor mein text bharoge to wo **har product** pe dikhne lagega.

### Icon naam

- **Feature highlights:** `perfume`, `ingredients`, `leaf`, `badge`, `shield`,
  `drop`, `energy`, `heart`, `star`, `lock`, `clock`, `flame`
- **Product badges:** `instagram`, `facebook`, `tiktok`, `france`, `globe`,
  `award`, `verified`, `star`, `leaf`

---

## 5. Seekhi hui baatein (dobara na dohrayi jayein)

**Shopify range setting mein zyada se zyada 101 steps** — `(max-min)/step`.
Ek baar `0–999 step 3` (333 steps) diya tha, Shopify ne poori file reject kar
di. Theme-check ye nahi pakadta, sirf upload ke waqt pata chalta hai.

**Range negative value nahi leta.** Negative chahiye to `number` field use
karo (Notice bar ka "Space above" isi liye typed field hai).

**CSS margins collapse hote hain.** Product form block ka apna 20px
`margin-bottom` hai — apni setting 0 karne se bhi gap kam nahi hota, upar
khinchne ke liye negative margin hi ek raasta hai.

**Theme ka `t4s_ratio` wrapper istemal mat karna.** Wo children ko absolute
position kar deta hai aur height ek `::before` spacer se leta hai — comparison
image usme 0 height ho gayi thi. Seedha `width`/`height` attributes se kaam
chalao.

**Lazysizes ke saath `width: auto` mat rakhna.** Image ka size uski file se
aata hai aur file ka size rendered width se chuna jata hai — feedback loop ban
jata hai aur logo kabhi bada nahi hota. Box se size do (`width: 100%` +
`object-fit: contain`).

**`shopify theme dev` chalu ho to local files dev theme pe overwrite hoti
rehti hain** — dev theme ke editor mein kiya gaya kaam mit sakta hai. Ek baar
Store network section isi tarah gaya tha.

**Shopify CDN page cache** — deploy ke baad live page pe purana version dikh
sakta hai. `?preview_theme_id=144548528304` se cache bypass hota hai.

**App ki CSS site tod sakti hai.** Ek app (`fs-bundles-quantity-breaks`) ne
`* { margin:0 !important; padding:0 !important }` daal diya tha — poori site ka
spacing khatam ho gaya tha. App walon ne scope theek kiya. Aisa lage to pehle
app CSS check karo, theme nahi.

---

## 6. Kaam ke links

- [Theme Editor (live)](https://faralondon.myshopify.com/admin/themes/144548528304/editor)
- [Product metafields](https://faralondon.myshopify.com/admin/settings/custom_data/product)
- [Live preview (cache bypass)](https://faralondon.com/?preview_theme_id=144548528304)
- [Dev theme preview](https://faralondon.myshopify.com/?preview_theme_id=146881347760)

---

## 7. Pending / khule masle

- **Social proof bar** — mobile pe text 29px lamba hai (374px chahiye, 345px
  milte hain). Message se lafz "happy" hatane se poora fit ho jayega.
- **Metafields** — Social proof ke liye `custom.proof_names` aur
  `custom.proof_message` abhi banani hain, phir 2 products pe values bharni hain.
- **COD WhatsApp confirmation** — Yes/No auto-reply ka kaam abhi shuru nahi
  hua. ~40–50 orders/day pe ready-made app (WizzCOD, AiSensy, Zoko, Wati)
  behtar rahega bajaye custom WhatsApp API build ke.
- **Pre-existing** — site pe 728px horizontal overflow hai jo
  `gallery_text_accordions` section se aata hai. Backup theme mein bhi
  maujood hai, yani purana masla hai.

---

## 8. Nayi chat mein kaise shuru karo

Ye file paste kar do ya kaho:

> "FA'RA London Shopify theme pe kaam kar raha hun. Folder
> `Desktop/local_theme_fara` mein `FARA-HANDOVER.md` hai — usse padh lo,
> usme poora context hai."
