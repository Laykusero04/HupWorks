# Shop / E-Commerce Feature - Options

> See [EXISTING_FEATURES.md](EXISTING_FEATURES.md) for what is already built in the app.

---

## Option A: Simple Product Shop (Easiest)

Freelancers sell physical or digital products alongside their services. Add a "Shop" tab to the app.

### Client Screens

| # | Screen | What it shows |
|---|--------|--------------|
| 1 | Shop Home | Product grid with filters (price, category, rating) |
| 2 | Product Detail | Images, price, description, sizes/colors, add to cart |
| 3 | Cart | Item list, quantity +/-, total price, go to checkout |
| 4 | Checkout | Shipping address, payment method, order summary, place order |
| 5 | Order Confirmation | "Order placed!" with order number |
| 6 | Shop Orders | Track product orders |

### Seller Screens

| # | Screen | What it shows |
|---|--------|--------------|
| 7 | Add Product | Form: name, photos, price, stock, category |
| 8 | My Products | Product list with edit, delete, stock count |

### Features
- Product categories
- Add to cart
- Quantity selector
- Shipping address form
- Payment using existing card/wallet
- Order status tracking
- Product reviews

### Best For
Apps where freelancers also sell tools, templates, presets, merchandise.

---

## Option B: Full Marketplace Shop (Medium)

Every seller gets their own store page. Like a mini Etsy or Shopify inside the app.

### Client Screens

| # | Screen | What it shows |
|---|--------|--------------|
| 1 | Shop Home | Featured shops, deals, trending products, categories |
| 2 | Store Page | Seller's shop - banner, bio, all their products |
| 3 | Product Detail | Image carousel, price, variants, reviews, related products |
| 4 | Cart | Items grouped by shop, quantities, subtotals |
| 5 | Wishlist | Products saved for later |
| 6 | Checkout | Address, shipping method, payment, coupon code, summary |
| 7 | Order Confirmation | Success + estimated delivery date |
| 8 | Order Tracking | Steps: Ordered > Shipped > Out for Delivery > Delivered |
| 9 | Order History | Past orders with reorder button |

### Seller Screens

| # | Screen | What it shows |
|---|--------|--------------|
| 10 | Shop Dashboard | Sales stats, revenue chart, top products |
| 11 | Add Product | Full form: name, description, images, price, variants, stock |
| 12 | Manage Products | Product list, quick edit, low stock alerts |
| 13 | Shop Setup | Shop name, logo, banner, description, policies |
| 14 | Shipping Setup | Shipping zones, rates, delivery time |
| 15 | Coupon Manager | Create discount codes (%, fixed, free shipping) |

### Features
- Product variants (size S/M/L, color red/blue)
- Coupon / promo codes
- Shipping tracking with steps
- Shop ratings
- Flash deals / sale banners
- Recently viewed products
- Buy again from history
- Multi-seller cart

### Best For
Apps that want a full marketplace with both services and products.

---

## Option C: Digital Products Only (Fastest)

Freelancers sell downloadable items - templates, fonts, presets, code, ebooks. No shipping. Instant delivery.

### Client Screens

| # | Screen | What it shows |
|---|--------|--------------|
| 1 | Digital Shop | Product grid, filter by type (template, preset, ebook) |
| 2 | Product Detail | Preview images, description, file info, buy now button |
| 3 | Cart | Simple list, total price, pay button (no shipping) |
| 4 | Checkout | Payment only, apply coupon |
| 5 | Purchase Done | Download link + "Go to My Purchases" |
| 6 | My Purchases | All bought items with download buttons |

### Seller Screens

| # | Screen | What it shows |
|---|--------|--------------|
| 7 | Upload Product | Upload file, add preview images, set price, description |
| 8 | My Products | Product list with sales count |
| 9 | Sales Report | Total sold, total earned, top products |

### Features
- Instant download after payment
- File preview (images, PDF first page)
- License type (personal / commercial - different prices)
- Bundle deals (buy 3 for $X)
- Free products
- Product reviews

### Best For
Creative freelancers selling templates, designs, presets, code snippets.

---

## Quick Comparison

| | Option A | Option B | Option C |
|--|----------|----------|----------|
| New screens | 8 | 15 | 9 |
| Shipping | Yes | Yes | No |
| Variants (size/color) | Basic | Full | No |
| Coupons | No | Yes | Yes |
| Order tracking | Simple | Full steps | Instant |
| Seller store page | No | Yes | No |
| Cart type | Simple | Multi-seller | Simple |
| Build effort | Short | Long | Shortest |

---

## New Components Needed (All Options)

| Component | What it does |
|-----------|-------------|
| ProductCard | Card with image, name, price, rating |
| CartIcon | Cart icon with item count badge |
| CartItem | Item row in cart (image, name, qty, price) |
| QuantitySelector | +/- buttons for quantity |
| PriceTag | Price display with sale strikethrough |
| AddToCartButton | Button that adds item to cart |
| EmptyCart | "Cart is empty" screen |
| ShopCategoryChip | Filter chips for categories |

---

## New Data Models (All Options)

| Model | Fields |
|-------|--------|
| Product | id, name, description, price, images, category, stock, rating, sellerId |
| CartItem | product, quantity, selectedVariant |
| Cart | items, totalPrice, itemCount |
| ShopOrder | id, items, totalPrice, status, date |

### Extra models per option

| Model | Used in | Fields |
|-------|---------|--------|
| ProductVariant | A, B | size, color, priceChange |
| ShippingAddress | A, B | name, street, city, zip, phone |
| Shop | B only | id, name, logo, banner, sellerId, rating |
| Coupon | B, C | code, discountType, value, minOrder, expiry |
| DigitalProduct | C only | fileUrl, fileSize, licenseType |

---

## Recommendation

- Want physical + digital products? **Start with Option A**
- Freelancers sell downloads only? **Start with Option C**
- Want the full experience? **Go with Option B**

You can start small (A or C) and grow into B later.

---

## Next Steps

1. Pick an option (A, B, or C)
2. I build all screens and components
3. Same code style as existing app
4. Same colors, fonts, and design
