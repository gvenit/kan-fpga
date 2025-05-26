#include "kan_bram_controller.h"

int bram_init(u16 DeviceId, XBram *Bram)
{
    int Status;
    XBram_Config *ConfigPtr;

    /*
     * Initialize the BRAM driver. If an error occurs then exit
     */

    /*
     * Lookup configuration data in the device configuration table.
     * Use this configuration info down below when initializing this
     * driver.
     */
    ConfigPtr = XBram_LookupConfig(DeviceId);
    if (ConfigPtr == (XBram_Config *)NULL)
        return XST_FAILURE;

    Status = XBram_CfgInitialize(Bram, ConfigPtr, ConfigPtr->CtrlBaseAddress);
    if (Status != XST_SUCCESS)
        return XST_FAILURE;

    InitializeECC(ConfigPtr, ConfigPtr->CtrlBaseAddress);

    /*
     * Execute the BRAM driver selftest.
     */
    Status = XBram_SelfTest(Bram, 0);
    if (Status != XST_SUCCESS)
        return XST_FAILURE;

    return XST_SUCCESS;
}
