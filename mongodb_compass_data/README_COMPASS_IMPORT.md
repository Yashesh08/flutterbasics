# How to Import into MongoDB Compass

These JSON files are formatted in MongoDB Extended JSON (EJSON) specifically for importing into MongoDB Compass.

---

## Files Included

1. [`menuitems.json`](file:///Users/yashesh/Downloads/flutterbasics-yashesh_213/mongodb_compass_data/menuitems.json) - Menu items with categories, prices, preparation times, and stock availability.
2. [`users.json`](file:///Users/yashesh/Downloads/flutterbasics-yashesh_213/mongodb_compass_data/users.json) - Seed users (`staff@campus.test`, `student@campus.test`, `admin@campus.test`) with bcrypt-hashed passwords.
3. [`orders.json`](file:///Users/yashesh/Downloads/flutterbasics-yashesh_213/mongodb_compass_data/orders.json) - Orders with `orderType` (`dine-in`, `takeaway`), calculated `expectedReadyAt` timestamps, and `estimatedPrepTime`.
4. [`all_collections.json`](file:///Users/yashesh/Downloads/flutterbasics-yashesh_213/mongodb_compass_data/all_collections.json) - Combined snapshot of all 3 collections.

---

## Step-by-Step Instructions in MongoDB Compass

### Step 1: Open MongoDB Compass
1. Launch **MongoDB Compass**.
2. Connect to your instance (default: `mongodb://localhost:27017` or `mongodb://127.0.0.1:27017`).
3. In the left sidebar, click on or create the **`canteen`** database.

### Step 2: Import `menuitems`
1. Under the `canteen` database, click on the **`menuitems`** collection (or click **Create Collection** and name it `menuitems`).
2. Click the **"Add Data"** button (green button with a downward arrow / dropdown).
3. Select **"Import JSON or CSV file"**.
4. In the file picker, select:
   `/Users/yashesh/Downloads/flutterbasics-yashesh_213/mongodb_compass_data/menuitems.json`
5. Ensure the file type is detected as **JSON**.
6. Click **"Import"**.

### Step 3: Import `users`
1. Under the `canteen` database, select or create the **`users`** collection.
2. Click **"Add Data"** → **"Import JSON or CSV file"**.
3. Choose:
   `/Users/yashesh/Downloads/flutterbasics-yashesh_213/mongodb_compass_data/users.json`
4. Click **"Import"**.

### Step 4: Import `orders`
1. Under the `canteen` database, select or create the **`orders`** collection.
2. Click **"Add Data"** → **"Import JSON or CSV file"**.
3. Choose:
   `/Users/yashesh/Downloads/flutterbasics-yashesh_213/mongodb_compass_data/orders.json`
4. Click **"Import"**.

---

### Demo Accounts Ready to Use
- **Staff / Admin:** `staff@campus.test` / password: `staff123`
- **Student:** `student@campus.test` / password: `student123`
