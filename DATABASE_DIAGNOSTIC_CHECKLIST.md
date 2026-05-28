# 🔍 Database Issues - Diagnostic Checklist

## ❓ Issue Summary
- Data not being saved to Supabase
- OTP not being generated/received

---

## ✅ Checklist 1: Verify Tables Were Created

1. Go to **Supabase Dashboard** → Your Project
2. Click **Table Editor** (left sidebar)
3. Look for these two tables:
   - ✓ `employee_profiles`
   - ✓ `verification_codes`

**If tables don't exist:**
- The SQL didn't run successfully
- Go to **SQL Editor** → Run the SQL again
- Check for error messages in red

**If tables exist:**
- Proceed to Checklist 2

---

## ✅ Checklist 2: Verify SQL Executed Properly

1. Click **SQL Editor**
2. Click the query you saved (should be "Employee profile and otp verification schema")
3. Check the **output at the bottom**:
   - ✓ No errors in red = SQL executed
   - ✗ Red errors = SQL failed

**Common errors & fixes:**

| Error | Fix |
|-------|-----|
| `permission denied` | Need to grant permissions - re-run the whole SQL |
| `relation already exists` | Drop the old tables first (drop commands should handle this) |
| `syntax error` | Copy the ENTIRE SQL file again, make sure no parts are missing |

---

## ✅ Checklist 3: Test the App with Detailed Logs

1. **Refresh your Flutter app** (Press 'r' in terminal)
2. **Open Chrome DevTools** (F12)
3. **Go to Console tab**
4. **Try signing up** with test data:
   - Employee ID: `TEST001`
   - Full Name: `Test User`
   - Mobile: `9876543210`
   - Email: `test001@prodine.com`
   - Password: `Test@123`

### Look for these messages in Console:

**✓ If working:**
```
✅ Supabase initialized successfully
🔐 Creating Supabase auth user...
👤 Starting employee signup for: test001@prodine.com
🌐 Supabase URL: https://pengkefnsyvpoaxtqedd.supabase.co
✅ Supabase client is initialized
🔍 Attempting to insert into table: employee_profiles
📤 Data to insert: {...}
✅ Data inserted successfully!
📥 Response: {...}
✅ Employee profile stored successfully
📱 Sending OTP to phone number: 9876543210
✅ OTP stored successfully in database
🔐 OTP for 9876543210: 123456
```

**✗ If failing, you'll see:**
```
❌ Insert error: [ERROR MESSAGE HERE]
```

---

## ✅ Checklist 4: Check Actual Data in Supabase

After trying signup, check if data exists:

1. Go to Supabase **Table Editor**
2. Click `employee_profiles` table
3. Should see your test record:
   - employee_id: TEST001
   - full_name: Test User
   - mobile_number: 9876543210
   - email: test001@prodine.com
   
4. Click `verification_codes` table
5. Should see a record with:
   - phone_number: 9876543210
   - otp: 123456 (or whatever code was generated)
   - is_verified: false

**If data appears:**
- ✅ Database is working!
- ✅ OTP should show in console

**If data doesn't appear:**
- ❌ Insert is failing
- ❌ Check error messages in console

---

## 📋 Common Issues & Solutions

### Issue: `undefined is not an object (evaluating '_client')`
**Cause:** Supabase not initialized
**Fix:**
- Make sure main.dart runs `await SupabaseConfig.initialize()`
- Check if `❌ Supabase initialization failed` appears in console

### Issue: `42P01: relation "employee_profiles" does not exist`
**Cause:** Table wasn't created
**Fix:**
- Verify tables in Supabase Table Editor
- If missing, re-run the SQL with DROP commands

### Issue: `23505: duplicate key value violates unique constraint`
**Cause:** Trying to insert duplicate email/phone/employee_id
**Fix:**
- Use different test data each time
- Or clear the table before testing

### Issue: `permission denied for schema public`
**Cause:** Permissions not granted
**Fix:**
- Re-run the SQL, especially the GRANT commands

### Issue: No error but data not saving
**Cause:** Silent failure
**Fix:**
- Look for logs that say "❌ Insert error"
- Copy the exact error message and send it

---

## 🎯 What to Send Me Next

**If it's still not working**, please send me:**

1. **Screenshot of Chrome Console** (F12) showing the error
2. **Confirmation of table creation** (Table Editor screenshot)
3. **Exact error message** from console
4. **Email you're testing with**

With this info, I can identify the exact issue!

---

## 🚀 Expected Flow When Working

```
Signup Form
    ↓
Click "Create Account"
    ↓
Validate form ✓
    ↓
Create auth user with email/password ✓
    ↓
Get user ID from auth ✓
    ↓
Insert employee_profiles record ✓
    ↓
Generate 6-digit OTP ✓
    ↓
Insert verification_codes record ✓
    ↓
Show OTP in console: 🔐 OTP for 9876543210: 123456 ✓
    ↓
Show verification screen ✓
    ↓
User enters OTP ✓
    ↓
Verify OTP matches database ✓
    ↓
Show dashboard ✓
```

---

## 📞 Debug Commands

**To clear all test data and start fresh:**

In Supabase SQL Editor:
```sql
DELETE FROM public.verification_codes;
DELETE FROM public.employee_profiles;
```

Then try signup again with fresh test data.

---

**Next Step:** Run through this checklist and let me know exactly where it breaks!
