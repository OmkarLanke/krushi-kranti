# Quick Fix: ExceptionInInitializerError with TypeTag :: UNKNOWN

> **Note**: For a comprehensive fix, see [INTELLIJ_EXCEPTIONINITIALIZER_FIX.md](./INTELLIJ_EXCEPTIONINITIALIZER_FIX.md)

## Quick Solution (5 minutes)

This error occurs when IntelliJ's annotation processors conflict with Lombok + MapStruct. **IntelliJ is not using Maven's annotation processor configuration.**

### Step 1: Clean and Rebuild (2 minutes)

1. **Stop any running applications** in IntelliJ
2. Go to **Build** → **Clean Project**
3. Go to **Build** → **Rebuild Project**
4. Wait for completion

### Step 2: Invalidate Caches (1 minute)

1. Go to **File** → **Invalidate Caches...**
2. Check **All** options
3. Click **Invalidate and Restart**
4. Wait for IntelliJ to restart

### Step 3: Reimport Maven (1 minute)

1. Open **Maven** tool window (View → Tool Windows → Maven)
2. Click **Reload All Maven Projects** (circular arrow icon)
3. Wait for "Maven projects need to be imported" notification
4. Click **Import Changes**

### Step 4: Verify Annotation Processing (1 minute)

1. Go to **File** → **Settings** → **Build, Execution, Deployment** → **Compiler** → **Annotation Processors**
2. Ensure **Enable annotation processing** is checked
3. Ensure **Obtain processors from project classpath** is selected
4. Click **Apply** and **OK**

### Step 4b: CRITICAL - Delegate Build to Maven

1. Go to **File** → **Settings** → **Build, Execution, Deployment** → **Build Tools** → **Maven**
2. ✅ **Check "Delegate IDE build/run actions to Maven"** (THIS IS CRITICAL!)
3. Click **Apply** and **OK**

### Step 5: Try Running Again

1. Right-click `AuthServiceApplication.java`
2. Select **Run 'AuthServiceApplication'**

## If Still Failing

### Option A: Use Maven to Run (Recommended)

```powershell
cd microservices\java-spring-microservices
mvn clean compile -pl :auth-service
mvn spring-boot:run -pl :auth-service
```

### Option B: Check Lombok Plugin

1. **File** → **Settings** → **Plugins**
2. Search for "Lombok"
3. Ensure it's **installed** and **enabled**
4. Restart IntelliJ

### Option C: Manual Annotation Processor Setup

1. **File** → **Settings** → **Build, Execution, Deployment** → **Compiler** → **Annotation Processors**
2. For `auth-service` module, click **+** to add processors manually:
   - `org.projectlombok:lombok:1.18.30`
   - `org.projectlombok:lombok-mapstruct-binding:0.2.0`
   - `org.mapstruct:mapstruct-processor:1.5.5.Final`
3. Ensure order is: Lombok → Lombok-MapStruct-Binding → MapStruct
4. Click **Apply** and **OK**

## Root Cause

The error happens because:
- Lombok and MapStruct both generate code at compile time
- They need to run in a specific order (Lombok first, then MapStruct)
- IntelliJ sometimes doesn't pick up the Maven configuration correctly
- The `lombok-mapstruct-binding` bridge ensures they work together

## Verification

After fixing, you should see:
- ✅ No compilation errors in IntelliJ
- ✅ Generated files in `auth-service/target/generated-sources/annotations`
- ✅ Application starts successfully

