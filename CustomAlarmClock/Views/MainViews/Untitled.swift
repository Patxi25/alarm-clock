using System;
using System.Linq;
using Microsoft.AspNetCore.Mvc;

namespace Codility.WarehouseApi
{
    public class WarehouseController : Controller
    {
        private readonly IWarehouseRepository _warehouseRepository;

        public WarehouseController(IWarehouseRepository warehouseRepository)
        {
            _warehouseRepository = warehouseRepository;
        }

        // Return OkObjectResult(IEnumerable<WarehouseEntry>)
        public IActionResult GetProducts()
        {
            return new OkObjectResult(_warehouseRepository.GetProductRecords());
        }

        // Return OkResult, BadRequestObjectResult(NotPositiveQuantityMessage), or BadRequestObjectResult(QuantityTooLowMessage)
        public IActionResult SetProductCapacity(int productId, int capacity)
        {
            if (capacity <= 0) {
                return new BadRequestObjectResult(new NotPositiveQuantityMessage());
            }

            Func<ProductRecord, bool> filterProduct = record => record.ProductId == productId;
            ProductRecord? productRecord = _warehouseRepository.GetProductRecords(filterProduct).FirstOrDefault();

            // TODO: This is a change I needed to make...
            // If no product record exists, we cannot proceed (make productRecord nullable)
            if (productRecord == null)
            {
                return new BadRequestObjectResult("Product does not exist.");
            }

            if (capacity < productRecord.Quantity) {
                return new BadRequestObjectResult(new QuantityTooLowMessage());
            }

            // TODO: This is a change I needed to make...
            _warehouseRepository.SetCapacityRecord(productId, capacity);

            return new OkResult();
        }

        // Return OkResult, BadRequestObjectResult(NotPositiveQuantityMessage), or BadRequestObjectResult(QuantityTooHighMessage)
        public IActionResult ReceiveProduct(int productId, int qty)
        {
            if (qty <= 0) {
                return new BadRequestObjectResult(new NotPositiveQuantityMessage());
            }

            Func<ProductRecord, bool> filterProduct = record => record.ProductId == productId;
            ProductRecord? productRecord = _warehouseRepository.GetProductRecords(filterProduct).FirstOrDefault();

            Func<CapacityRecord, bool> filterCapacity = record => record.ProductId == productId;
            CapacityRecord? capacityRecord = _warehouseRepository.GetCapacityRecords(filterCapacity).FirstOrDefault();

            // TODO: This is a change I needed to make...
            // If no product record exists, we cannot proceed (make productRecord and capacityRecord nullable)
            if (capacityRecord == null)
            {
                return new BadRequestObjectResult(new QuantityTooHighMessage());
            }

            // TODO: This is a change I needed to make...
            int currentCapacity = capacityRecord?.Capacity ?? 0;
            int currentQuantity = productRecord?.Quantity ?? 0;

            // TODO: This is a change I needed to make...
            // If no capacity record exists, we cannot proceed (make capacityRecord nullable)
            if (currentCapacity < currentQuantity + qty) {
                return new BadRequestObjectResult(new QuantityTooLowMessage());
            }

            // TODO: This is a change I needed to make...
            _warehouseRepository.SetProductRecord(productId, productRecord.Quantity);

            return new OkResult();
        }

        // Return OkResult, BadRequestObjectResult(NotPositiveQuantityMessage), or BadRequestObjectResult(QuantityTooHighMessage)
        public IActionResult DispatchProduct(int productId, int qty)
        {
            if (qty <= 0) {
                return new BadRequestObjectResult(new NotPositiveQuantityMessage());
            }

            Func<ProductRecord, bool> filterProduct = record => record.ProductId == productId;
            ProductRecord? productRecord = _warehouseRepository.GetProductRecords(filterProduct).FirstOrDefault();

            
            if (productRecord == null)
            {
                // If no product record exists, treat it as exceeding the available quantity
                return new BadRequestObjectResult(new QuantityTooHighMessage());
            }

            if (productRecord.Quantity < qty) {
                return new BadRequestObjectResult(new QuantityTooLowMessage());
            }

            // TODO: This is a change I needed to make...
            _warehouseRepository.SetProductRecord(productId, productRecord.Quantity);

            return new OkResult();
        }
    }
}

public interface IWarehouseRepository {
    void SetCapacityRecord(int productId, int capacity);
    IEnumerable<CapacityRecord> GetCapacityRecords();
    IEnumerable<CapacityRecord> GetCapacityRecords(Func<CapacityRecord, bool> filter);

    void SetProductRecord(int productId, int capacity);
    IEnumerable<ProductRecord> GetProductRecords();
    IEnumerable<ProductRecord> GetProductRecords(Func<ProductRecord, bool> filter);
}

public class CapacityRecord {
    public int ProductId { get; set; }
    public int Capacity { get; set; }
}

public class ProductRecord {
    public int ProductId { get; set; }
    public int Quantity { get; set; }
}
