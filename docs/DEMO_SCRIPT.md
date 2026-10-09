# LoopServe 3.0 — Hackathon Demonstration Guide

## Step-by-Step Presentation Script

### Step 1: Product Identity & Concept Introduction (30 seconds)
1. Open the application in Web / Desktop browser (`flutter run -d chrome`).
2. Point out the header **Mode Switcher Bar**:
   - Show that **Development Fixture Mode** is active for standalone testing.
   - Point out the **Connection Status Badge** (`CONNECTED / FIXTURE MODE`).
3. Highlight the **EMBER design system**:
   - Deep charcoal background (`#111110`), warm ember orange accent (`#E87532`), Playfair Display editorial typography.

---

### Step 2: Interactive 3D Dish Studio Experience (60 seconds)
1. Click **Explore 3D Menu** or select **Ember Signature Wagyu Burger**.
2. Show the **3D Studio Viewport**:
   - Rotate the 3D model using pointer/mouse drag or the **Rotate Left / Rotate Right** buttons.
   - Click **Reset Camera** to restore default framing.
3. Demonstrate **Customization & Dynamic Price Sync**:
   - Select **Double Patty** (+`$8.50`). Show that the price updates instantly from `$24.50` to `$33.00`.
   - Select **Melted Cheddar Extra** (+`$3.00`). Show that the price breakdown updates dynamically in real time.
   - Click **Add to Cart**.

---

### Step 3: Shopping Cart & Idempotent Checkout (40 seconds)
1. Navigate to **Cart**.
2. Point out that exact selected customization options are preserved in the line item.
3. Click **Proceed to Checkout**.
4. Point out the **Idempotency Protection Active** badge at the top:
   - Displays unique key: `idemp-uuid-xxxx`.
   - Explain: Retrying a request after network failure reuses this exact key, preventing duplicate order tickets.
5. Enter Customer Name (`Alexander Wright`) and click **Place Authoritative Order**.

---

### Step 4: Live Order Tracking & Staff Operations Handover (60 seconds)
1. The app navigates to **Live Order Tracking**:
   - Shows status: **PENDING**.
2. Switch to **Staff Operations** using the header role switcher (`⚡ Staff Operations`).
3. Open **Live Order Queue**:
   - Show the newly placed ticket `#8044` for Alexander Wright appearing in the queue with full customization breakdown.
4. Progress the order through kitchen stages:
   - Click **Accept Order** -> Status changes to **ACCEPTED**.
   - Click **Start Preparation** -> Status changes to **PREPARING**.
   - Click **Mark Ready for Pickup** -> Status changes to **READY**.
5. Switch back to **Customer View**:
   - Show the progress timeline updated in real time.
6. Click **View Order Receipt** to display the formal **Tax Receipt**.

---

### Step 5: Inventory Competition Scenario (30 seconds)
1. In Staff View, open **Menu & Portion Inventory**.
2. Find **Ember Dark Chocolate Molten Lava Cake** (set to 1 available portion).
3. Demonstrate two customers attempting to purchase the last portion:
   - Customer A purchases 1 portion -> portion count drops to 0 (**SOLD OUT**).
   - Customer B attempts to checkout -> system rejects transaction with clear **Inventory Conflict Warning**.
