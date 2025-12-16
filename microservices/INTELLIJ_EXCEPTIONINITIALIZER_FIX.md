# Fix: ExceptionInInitializerError in IntelliJ IDEA

## Problem
- ❌ **IntelliJ**: `ExceptionInInitializerError` with `TypeTag :: UNKNOWN`
- ✅ **Cursor/Maven**: Works perfectly

**Root Cause**: IntelliJ IDEA is not using Maven's annotation processor configuration. It's trying to compile with its own compiler settings, which conflicts with Lombok + MapStruct.

## Solution: Force IntelliJ to Use Maven Configuration

### Method 1: Configure IntelliJ to Use Maven (Recommended)

#### Step 1: Enable Annotation Processing Globally

1. Open **File** → **Settings** (or `Ctrl+Alt+S`)
2. Navigate to: **Build, Execution, Deployment** → **Compiler** → **Annotation Processors**
3. Configure:
   - ✅ **Enable annotation processing** (CHECK THIS)
   - Select: **Obtain processors from project classpath**
   - ✅ **Store generated sources relative to**: Select **Module content root**
   - **Generated sources directory**: `target/generated-sources/annotations`
4. Click **Apply**

#### Step 2: Configure Per-Module Settings

1. Still in **Settings** → **Build, Execution, Deployment** → **Compiler** → **Annotation Processors**
2. In the **Default annotation processor profile** section, you should see your modules
3. For **auth-service** module:
   - Ensure it's listed
   - If not, click **+** and add it
   - Ensure **Enable annotation processing** is checked for this module
4. Click **Apply** and **OK**

#### Step 3: Configure Build Tool

1. Go to **File** → **Settings** → **Build, Execution, Deployment** → **Build Tools** → **Maven**
2. Ensure:
   - ✅ **Use Maven wrapper** (if you have one, otherwise use system Maven)
   - ✅ **Delegate IDE build/run actions to Maven** (THIS IS CRITICAL)
3. Click **Apply** and **OK**

#### Step 4: Invalidate Caches

1. **File** → **Invalidate Caches...**
2. Check **All** options:
   - ✅ Clear file system cache and Local History
   - ✅ Clear downloaded shared indexes
   - ✅ Clear VCS Log caches and indexes
3. Click **Invalidate and Restart**
4. Wait for IntelliJ to restart completely

#### Step 5: Reimport Maven Project

1. Open **Maven** tool window:
   - **View** → **Tool Windows** → **Maven** (or press `Alt+4`)
2. In the Maven tool window:
   - Right-click on the root project (`java-spring-microservices`)
   - Select **Maven** → **Reload Project**
   - OR click the **Reload All Maven Projects** button (circular arrow icon)
3. Wait for Maven to finish importing
4. If you see a notification: **"Maven projects need to be imported"**, click **Import Changes**

#### Step 6: Verify Generated Sources

1. Go to **File** → **Project Structure** (or `Ctrl+Alt+Shift+S`)
2. Navigate to **Modules** → **auth-service**
3. Under **Sources** tab:
   - Look for `target/generated-sources/annotations`
   - If it exists but is not marked as "Generated Sources Root":
     - Right-click on it → **Mark Directory as** → **Generated Sources Root**
   - Look for `target/generated-sources/protobuf/java`
     - Right-click → **Mark Directory as** → **Generated Sources Root**
   - Look for `target/generated-sources/protobuf/grpc-java`
     - Right-click → **Mark Directory as** → **Generated Sources Root**
4. Click **Apply** and **OK**

#### Step 7: Clean and Rebuild

1. **Build** → **Clean Project**
2. Wait for completion
3. **Build** → **Rebuild Project**
4. Wait for completion (this may take 2-3 minutes)

#### Step 8: Verify Lombok Plugin

1. **File** → **Settings** → **Plugins**
2. Search for **"Lombok"**
3. Ensure:
   - ✅ Plugin is **installed**
   - ✅ Plugin is **enabled**
4. If not installed:
   - Click **Marketplace**
   - Search for "Lombok"
   - Click **Install**
   - Restart IntelliJ when prompted

#### Step 9: Try Running Again

1. Right-click on `AuthServiceApplication.java`
2. Select **Run 'AuthServiceApplication'**
3. If it still fails, proceed to Method 2

---

### Method 2: Use Maven to Run (Workaround)

If IntelliJ still has issues, use Maven directly:

#### Option A: Run via Maven in IntelliJ Terminal

1. Open IntelliJ's built-in terminal: **View** → **Tool Windows** → **Terminal** (or `Alt+F12`)
2. Run:
   ```powershell
   cd microservices\java-spring-microservices
   mvn clean compile -pl :auth-service
   mvn spring-boot:run -pl :auth-service
   ```

#### Option B: Create Maven Run Configuration

1. **Run** → **Edit Configurations...**
2. Click **+** → **Maven**
3. Configure:
   - **Name**: `Auth Service (Maven)`
   - **Working directory**: `$PROJECT_DIR$/microservices/java-spring-microservices`
   - **Command line**: `spring-boot:run -pl :auth-service`
   - **Before launch**: Add → **Run Maven Goal** → `clean compile -pl :auth-service`
4. Click **Apply** and **OK**
5. Run this configuration instead of the Java application

---

### Method 3: Manual Annotation Processor Configuration

If Methods 1 and 2 don't work:

1. **File** → **Settings** → **Build, Execution, Deployment** → **Compiler** → **Annotation Processors**
2. For **auth-service** module, click **+** to add processors:
   - **Processor FQ Name**: `lombok.launch.AnnotationProcessorHider$AnnotationProcessor`
   - **Processor path**: `org.projectlombok:lombok:1.18.30`
   - Click **OK**
3. Add second processor:
   - **Processor FQ Name**: `org.mapstruct.ap.MappingProcessor`
   - **Processor path**: `org.mapstruct:mapstruct-processor:1.5.5.Final`
   - Click **OK**
4. Ensure order is: Lombok first, then MapStruct
5. Click **Apply** and **OK**
6. Rebuild project

---

## Verification Checklist

After following the steps, verify:

- [ ] **No compilation errors** in IntelliJ's Problems window
- [ ] **Generated files exist** in:
  - `auth-service/target/generated-sources/annotations/`
  - `auth-service/target/generated-sources/protobuf/java/`
  - `auth-service/target/generated-sources/protobuf/grpc-java/`
- [ ] **Lombok plugin** is installed and enabled
- [ ] **Annotation processing** is enabled in Settings
- [ ] **Maven delegate** is enabled (delegate IDE build to Maven)
- [ ] **Application starts** without `ExceptionInInitializerError`

---

## Why This Happens

1. **IntelliJ uses its own compiler** (Eclipse Compiler for Java - ECJ) by default
2. **Maven uses javac** (Oracle/OpenJDK compiler)
3. **Annotation processors** behave differently between the two
4. **Lombok + MapStruct** require specific ordering that Maven handles correctly, but IntelliJ needs explicit configuration

## Why It Works in Cursor

Cursor likely:
- Uses Maven directly for compilation
- Doesn't interfere with annotation processing
- Respects the `pom.xml` configuration automatically

---

## Still Having Issues?

### Check Java Version

```powershell
java -version
# Should show Java 21
```

### Check Maven Version

```powershell
mvn -version
# Should show Maven 3.x with Java 21
```

### Force Maven Compilation

```powershell
cd microservices\java-spring-microservices
mvn clean install -DskipTests -pl :auth-service
```

Then refresh IntelliJ project.

### Check IntelliJ Java Version

1. **File** → **Project Structure** → **Project**
2. Ensure **SDK** is set to **Java 21**
3. Ensure **Language level** is **21 - Preview** (or **21**)

---

## Quick Reference: Critical Settings

| Setting | Location | Value |
|---------|----------|-------|
| Enable annotation processing | Settings → Compiler → Annotation Processors | ✅ Enabled |
| Obtain processors from | Settings → Compiler → Annotation Processors | Project classpath |
| Delegate to Maven | Settings → Build Tools → Maven | ✅ Enabled |
| Lombok Plugin | Settings → Plugins | ✅ Installed & Enabled |
| Generated Sources | Project Structure → Modules → Sources | Marked as Generated |

---

## Success Indicators

✅ **IntelliJ compiles without errors**  
✅ **No `ExceptionInInitializerError`**  
✅ **Application runs successfully**  
✅ **Generated code is visible in `target/generated-sources`**

If you see these, you're good to go! 🎉

