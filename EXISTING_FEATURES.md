# Freelancer Service App - Existing Features

## App Overview

A freelancer marketplace app with two user types: **Client** (buyer) and **Seller** (freelancer).

---

## Client Side

### Authentication
- Login
- Sign Up
- OTP Verification
- Forgot Password

### Home
- Search bar
- Category grid (Graphics Design, Video Editing, Digital Marketing, etc.)
- Popular services list
- Top sellers list
- Recently viewed

### Services
- Service detail page with image carousel
- Reviews and ratings (5-star)
- Related services
- Add to favorites

### Orders
- Place an order with requirements form
- Order list with filters (Active, Pending, Completed, Cancelled)
- Order detail page
- Order delivery tracking

### Jobs
- Post a job
- Manage job posts
- View freelancer offers

### Payments
- Credit/debit card form (animated card UI)
- Wallet balance / deposit
- Transaction history

### Other
- Favorites list
- Notifications
- Chat / messages with sellers
- Profile management
- Invite / referral
- Report issues
- Settings (language, policy, about)

---

## Seller Side

### Authentication
- Login
- Sign Up
- Verification
- Forgot Password
- Profile setup wizard

### Home / Dashboard
- Performance chart
- Statistics (pie chart - impressions, interactions, reach)
- Earnings tracking with period filter
- My services list

### Services
- Create new service (full form with images, pricing, description)
- Manage services (edit, delete)

### Orders
- Order list with status filters
- Order detail page
- Deliver order
- Review client after order

### Buyer Requests
- Browse buyer/client requests
- View request details
- Create and send offer/quote

### Payments
- Add payment method (PayPal, Credit Card, Bkash)
- Withdraw money
- Withdraw history
- Transaction history

### Other
- Favorites
- Notifications
- Chat / messages with clients
- Profile management
- Report issues
- Settings (language, policy, about, invite)

---

## Shared Features

| Feature | Details |
|---------|---------|
| Chat | Real-time messaging between client and seller |
| Notifications | Notification list screen |
| Favorites | Save services or sellers |
| Search | Search bar with results |
| Categories | Grid layout with icons |
| Ratings | 5-star system with bar breakdown |
| Image Carousel | Swipeable image gallery |
| Bottom Navigation | 5 tabs (Home, Messages, Middle Action, Orders, Profile) |
| Wallet | Balance display, deposit, transactions |

---

## Design System

| Item | Value |
|------|-------|
| Primary Color | Green (#69B22A) |
| Dark Color | Dark Blue (#121F3E) |
| Font | Inter (Google Fonts) |
| Icons | Iconly + Font Awesome |
| Buttons | Rounded green (40px radius) |
| Input Fields | Bordered with 8px radius |
| Scroll | Bouncing physics |

---

## Tech Stack

| Item | Value |
|------|-------|
| Framework | Flutter |
| State | StatefulWidget + setState |
| Navigation | MaterialPageRoute (push/pop) |
| Backend | None (UI only, demo data) |
| Key Packages | carousel_slider, flutter_credit_card, pie_chart, google_fonts, nb_utils, pinput |

---

## Screen Count

- Client screens: ~25
- Seller screens: ~30
- Shared screens: ~5
- Total: ~60 screens
