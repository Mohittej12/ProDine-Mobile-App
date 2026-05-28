# 🔧 Employee Auth - Troubleshooting Guide

## 📋 Issues to Fix

### **Issue 1: Data not storing in Supabase**
### **Issue 2: OTP not being generated/logged**

---

## ✅ Checklist - Fix the Database

### **Step 1: Update Supabase Tables**

1. Open **Supabase Dashboard** → Go to your project
2. Click **SQL Editor** 
3. Click **+ New Query**
4. **Copy ALL SQL** from this file: `EMPLOYEE_AUTH_DATABASE_SCHEMA_FIXED.sql`
5. **Paste it** into the SQL editor
6. Click **Run** (or Ctrl+Enter)
7. Wait for success message ✅

### **What this does:**
- ✅ Drops old tables with bad RLS policies
- ✅ Creates fresh tables without RLS (for development)
- ✅ Grants permissions to anonymous key
- ✅ Creates indexes for better performance

---

## 🧪 Step 2: Test the Signup with Console Logs

### **In Flutter App:**

1. Open Chrome DevTools (F12)
2. Go to **Console** tab
3. Clear any old messages
4. Try the signup flow again:
   - Employee ID: `TEST001`
   - Full Name: `Test User`
   - Mobile: `9876543210`
   - Email: `test@supabase@prodine.com`
   - Password: `Test@123`

### **What to Look For:**

**If it works, you'll see:**
```
✅ Auth user created with ID: [UUID]
💾 Storing employee profile in database: {...}
✅ Employee profile stored successfully
📱 Sending OTP to phone number: 9876543210
🔐 Generated OTP: 123456
✅ OTP stored successfully in database
🔐 OTP for 9876543210: 123456 (Expires in 10 minutes)
```

**If it fails, you'll see error messages like:**
```
❌ Employee signup error: [error details]
❌ Send OTP error: [error details]
```

---

## 🐛 Common Errors & Solutions

### **Error: "relation 'public.employee_profiles' does not exist"**
**Solution:** 
- The tables weren't created. Run the SQL from `EMPLOYEE_AUTH_DATABASE_SCHEMA_FIXED.sql`
- Check if the SQL ran without errors in Supabase

### **Error: "permission denied"**
**Solution:**
- RLS policies are blocking access
- Run the FIXED SQL file which disables RLS for development

### **Error: "violates unique constraint"**
**Solution:**
- The Employee ID or Phone Number already exists
- Use different test data:
  - Employee ID: `TEST002`, `TEST003`, etc.
  - Phone: `9876543211`, `9876543212`, etc.

### **No OTP showing in console**
**Solution:**
- The sendOTP function isn't being called
- Check for errors BEFORE the OTP step
- The signup might be failing earlier

---

## 📊 Verify in Supabase Dashboard

After trying signup, check if data was stored:

1. Go to **Supabase** → **Table Editor**
2. Select `employee_profiles` table
3. Should see your test record ✅
4. Select `verification_codes` table
5. Should see OTP code ✅

---

## 🔄 If Still Not Working

After running the SQL and retrying:

1. **Open Chrome DevTools Console (F12)**
2. **Try signup again**
3. **Copy ALL error messages** (take screenshot or copy text)
4. **Send me the exact error messages**

This will help me identify exactly what's wrong.

---

## 🚀 Next After Fix

Once data is storing and OTP is generating:
1. Enter the 6-digit OTP you see in console
2. Click "Verify Code"
3. Should see Employee Dashboard ✅

---

## 📞 Quick Reference

| What | Where to Check |
|------|----------------|
| OTP code | Chrome Console (F12) |
| Stored data | Supabase → Table Editor |
| Error messages | Chrome Console (F12) |
| Signup logs | Chrome Console (F12) |

---

## ⚠️ Important Notes

- Use **Chrome console** (F12), not terminal
- OTP expires in **10 minutes**
- Data should appear in Supabase **instantly**
- If no logs appear, signup is failing before OTP step
- RLS is **DISABLED for development** (enable for production later)

---

**Status**: Updated with enhanced logging and new SQL. Run the FIXED SQL and test again!
