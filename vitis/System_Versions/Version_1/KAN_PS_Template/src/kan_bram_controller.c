#include "kan_bram_controller.h"

/**
 * This function ensures that ECC in the BRAM is initialized if no hardware
 * initialization is available. The ECC bits are initialized by reading and
 * writing data in the memory. This code is not optimized to only read data
 * in initialized sections of the BRAM.
 *
 * @param	bram_config is a reference to a structure containing information
 *		about a specific BRAM device.
 * @param 	effetive_addr is the device base address in the virtual memory
 *		address space.
 */
void InitializeECC(XBram_Config *bram_config, uint32_t effetive_addr)
{
    uint32_t Addr;
    volatile uint32_t Data;

    if (bram_config->EccPresent &&
        bram_config->EccOnOffRegister &&
        bram_config->EccOnOffResetValue == 0 &&
        bram_config->WriteAccess != 0)
    {
        for (Addr = bram_config->MemBaseAddress;
             Addr < bram_config->MemHighAddress; Addr += 4)
        {
            Data = XBram_In32(Addr);
            XBram_Out32(Addr, Data);
        }
        XBram_WriteReg(effetive_addr, XBRAM_ECC_ON_OFF_OFFSET, 1);
    }
}

kan_status_t kan_bram_ctr_init(uint16_t bram_controller_id, XBram *bram_controller_handler)
{
    kan_status_t status;

    XBram_Config *bram_config;

    bram_config = XBram_LookupConfig(bram_controller_id);
    if (bram_config == NULL)
        return STATUS_NULL_POINTER_REF;

    status = XBram_CfgInitialize(bram_controller_handler, bram_config, bram_config->CtrlBaseAddress);
    if (status != STATUS_OK)
        return STATUS_BRAMC_INIT_FAILURE;

    InitializeECC(bram_config, bram_config->CtrlBaseAddress);

    /*
     * Execute the BRAM driver selftest.
     */
    status = XBram_SelfTest(bram_controller_handler, 0);
    if (status != STATUS_OK)
        return STATUS_BRAMC_INIT_FAILURE;

    return STATUS_OK;
}
