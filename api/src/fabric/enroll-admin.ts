import * as FabricCAServices from 'fabric-ca-client';
import { Wallets, X509Identity } from 'fabric-network';
import * as fs from 'fs';
import * as path from 'path';
import { EnrollAdminDto } from 'src/dto';

export const enrollAdmin = async (admin: EnrollAdminDto) => {
  let msg = ``;
  try {
    // Load the network configuration
    const ccpPath = path.resolve(__dirname, process.env.HLF_CCP_PATH);
    const ccp = JSON.parse(fs.readFileSync(ccpPath, 'utf8'));

    // Create a new CA client for interacting with the CA.
    const caURL = ccp.certificateAuthorities[process.env.HLF_ORG_CA].url;
    const ca = new FabricCAServices(caURL);

    // Create a new file system based wallet for managing identities.
    const walletPath = path.join(process.cwd(), 'wallet');
    const wallet = await Wallets.newFileSystemWallet(walletPath);
    console.log(`Wallet path: ${walletPath}`);

    // Check to see if we've already enrolled the admin user.
    const adminExists = await wallet.get(admin.name);
    if (adminExists) {
      msg = `An identity for the user ${admin.name} already exists in the wallet`;
      console.log(msg);
      return msg;
    }
    const enrollment = await ca.enroll({
      enrollmentID: admin.name,
      enrollmentSecret: admin.password,
    });
    const x509Identity: X509Identity = {
      credentials: {
        certificate: enrollment.certificate,
        privateKey: enrollment.key.toBytes(),
      },
      mspId: process.env.HLF_MSPID,
      type: 'X.509',
    };
    await wallet.put(admin.name, x509Identity);
    msg = `Successfully enrolled user ${admin.name} and imported it into the wallet`;
    console.log(msg);
    // return msg;
    return await wallet.get(admin.name);
  } catch (error) {
    msg = `Failed to enroll user ${admin.name}: ${error}`;
    console.error(msg);
    return msg;
  }
};
