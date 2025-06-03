#include "kan_bram_controller.h"

int bram_init(u16 bram_controller_id, XBram *bram_controller_handler)
{
    int status;
    XBram_Config *bram_config;

    /**
     * Initialize the BRAM driver. If an error occurs then exit
     */

    /**
     * Lookup configuration data in the device configuration table.
     * Use this configuration info down below when initializing this
     * driver.
     */

    bram_config = XBram_LookupConfig(bram_controller_id);
    if (bram_config == (XBram_Config *)NULL)
        return XST_FAILURE;

    status = XBram_CfgInitialize(bram_controller_handler, bram_config, bram_config->CtrlBaseAddress);
    if (status != XST_SUCCESS)
        return XST_FAILURE;

    InitializeECC(bram_config, bram_config->CtrlBaseAddress);

    /*
     * Execute the BRAM driver selftest.
     */
    status = XBram_SelfTest(bram_controller_handler, 0);
    if (status != XST_SUCCESS)
        return XST_FAILURE;

    return XST_SUCCESS;
}
