# IntelliJ IDEA Setup for Krushi Kranti Microservices

## Fixing Annotation Processor Issues

If you encounter `ExceptionInInitializerError` with `TypeTag :: UNKNOWN` in IntelliJ, this is a **Lombok + MapStruct annotation processor conflict**. Follow these steps in order:

### Step 1: Invalidate Caches and Restart

1. Go to **File** → **Invalidate Caches...**
2. Check all options:
   - Clear file system cache and Local History
   - Clear downloaded shared indexes
   - Clear VCS Log caches and indexes
3. Click **Invalidate and Restart**
4. Wait for IntelliJ to restart

### Step 2: Configure Annotation Processing

1. Go to **File** → **Settings** (or **IntelliJ IDEA** → **Preferences** on macOS)
2. Navigate to **Build, Execution, Deployment** → **Compiler** → **Annotation Processors**
3. Enable annotation processing:
   - ✅ Check **Enable annotation processing**
   - Select **Obtain processors from project classpath**
   - **IMPORTANT**: For `auth-service` module, ensure the processor path order is:
     1. `lombok` (org.projectlombok:lombok)
     2. `lombok-mapstruct-binding` (org.projectlombok:lombok-mapstruct-binding:0.2.0)
     3. `mapstruct-processor` (org.mapstruct:mapstruct-processor)
4. Click **Apply** and **OK**

### Step 3: Configure Project SDK and Language Level

1. Go to **File** → **Project Structure** (or press `Ctrl+Alt+Shift+S`)
2. Under **Project Settings** → **Project**:
   - **SDK**: Java 21
   - **Language level**: 21 - Preview
3. Under **Project Settings** → **Modules**:
   - Select each module (`api-gateway`, `auth-service`)
   - Ensure **Language level** is set to **21 - Preview**
4. Click **Apply** and **OK**

### Step 4: Reimport Maven Project

1. Open the **Maven** tool window (View → Tool Windows → Maven)
2. Right-click on the root project (`java-spring-microservices`)
3. Select **Maven** → **Reload Project**
4. **OR** click the **Reload All Maven Projects** button (circular arrow icon)
5. Wait for Maven to download dependencies and process annotations
6. **Verify**: Check that IntelliJ shows "Maven projects need to be imported" notification and click **Import Changes**

### Step 5: Rebuild Project

1. Go to **Build** → **Rebuild Project**
2. Wait for the build to complete
3. Check the **Build** tool window for any errors

### Step 6: Run Configuration

1. Right-click on `AuthServiceApplication.java`
2. Select **Run 'AuthServiceApplication'**
3. If errors persist, try **Run** → **Edit Configurations...**
4. Ensure the **JRE** is set to Java 21

## Alternative: Use Maven to Run

If IntelliJ continues to have issues, you can run the service using Maven:

```powershell
cd microservices\java-spring-microservices
mvn spring-boot:run -pl :auth-service
```

## Troubleshooting

### If annotation processing still fails:

1. **Check Lombok Plugin**:
   - Go to **File** → **Settings** → **Plugins**
   - Search for "Lombok" and ensure it's installed and enabled
   - Restart IntelliJ

2. **Check Generated Sources**:
   - Go to **File** → **Project Structure** → **Modules**
   - Select `auth-service`
   - Under **Sources**, ensure these are marked as **Generated Sources Root**:
     - `target/generated-sources/annotations`
     - `target/generated-sources/protobuf/java`
     - `target/generated-sources/protobuf/grpc-java`

3. **Manual Build**:
   ```powershell
   cd microservices\java-spring-microservices
   mvn clean install -DskipTests
   ```
   Then refresh IntelliJ project

4. **Check Java Version**:
   ```powershell
   java -version
   ```
   Should show Java 21

## Verification

After following these steps, you should be able to:
- ✅ Build the project without errors
- ✅ Run `AuthServiceApplication` successfully
- ✅ See generated code in `target/generated-sources`

