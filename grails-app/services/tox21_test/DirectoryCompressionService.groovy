package tox21_test

import java.util.zip.ZipOutputStream
import java.nio.file.Files
import java.util.zip.ZipEntry

class DirectoryCompressionService {

    //TODO: transfer compression logic from zipzap.groovy

    def makeZip(String zip, String dir) {
        FileOutputStream fos = new FileOutputStream(dir + "/" + zip);
        ZipOutputStream zos = new ZipOutputStream(fos);
        addDirToZipArchive(zos, new File(dir), null, zip);
        zos.flush();
        fos.flush();
        zos.close();
        fos.close();
    }

    public static void addDirToZipArchive(ZipOutputStream zos, File fileToZip, String parentDirectoryName, String ignore) throws Exception {
        if (fileToZip == null || !fileToZip.exists() || fileToZip.getName() == "CASRNs.txt") { //don't add the temporary casrns zip file used for re-enrichment
            return;
        }

        String zipEntryName = fileToZip.getName();
        if (parentDirectoryName!=null && !parentDirectoryName.isEmpty()) {
            zipEntryName = parentDirectoryName + "/" + fileToZip.getName();
        }

        if (fileToZip.isDirectory()) {
            System.out.println("+" + zipEntryName);
            for (File file : fileToZip.listFiles()) {
                addDirToZipArchive(zos, file, zipEntryName, ignore);
            }
        } else {
            System.out.println("   " + zipEntryName);
            if (zipEntryName.endsWith(ignore)) {
                return
            }
            byte[] buffer = new byte[1024];
            FileInputStream fis = new FileInputStream(fileToZip);
            zos.putNextEntry(new ZipEntry(zipEntryName));
            int length;
            while ((length = fis.read(buffer)) > 0) {
                zos.write(buffer, 0, length);
            }
            zos.closeEntry();
            fis.close();
        }
    }
}
