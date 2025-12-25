using System;
using System.Data.Entity;
using System.Linq;
using System.Net.Mail;
using System.Web.Mvc;
using devShop.Models;
using log4net;

namespace devShop.Controllers
{
    public class ProductsController : Controller
    {
        private static readonly ILog log = LogManager.GetLogger(typeof(ProductsController));
        private DevShopContext db = new DevShopContext();

        // GET: Products
        public ActionResult Index(int? categoryId)
        {
            try
            {
                log.Info($"Products/Index accessed, categoryId: {categoryId}");

                var query = db.Products.Include(p => p.Category).Where(p => p.IsActive);

                if (categoryId.HasValue)
                {
                    query = query.Where(p => p.CategoryID == categoryId.Value);
                    var category = db.Categories.Find(categoryId.Value);
                    ViewBag.CategoryName = category?.CategoryName;
                }

                var products = query.OrderBy(p => p.ProductName).ToList();

                // Carica categorie per il menu
                ViewBag.Categories = db.Categories.Where(c => c.IsActive).OrderBy(c => c.CategoryName).ToList();

                return View(products);
            }
            catch (Exception ex)
            {
                log.Error("Error in Products/Index", ex);
                ViewBag.Error = "Si è verificato un errore durante il caricamento dei prodotti.";
                return View("Error");
            }
        }

        // GET: Products/Details/5
        public ActionResult Details(int? id)
        {
            if (id == null)
            {
                log.Warn("Products/Details accessed without id");
                return new HttpStatusCodeResult(System.Net.HttpStatusCode.BadRequest);
            }

            try
            {
                log.Info($"Products/Details accessed, id: {id}");

                var product = db.Products.Include(p => p.Category).FirstOrDefault(p => p.ProductID == id);

                if (product == null)
                {
                    log.Warn($"Product not found, id: {id}");
                    return HttpNotFound();
                }

                return View(product);
            }
            catch (Exception ex)
            {
                log.Error($"Error in Products/Details for id: {id}", ex);
                ViewBag.Error = "Si è verificato un errore durante il caricamento del prodotto.";
                return View("Error");
            }
        }

        // POST: Products/Buy
        [HttpPost]
        public ActionResult Buy(int productId, string customerEmail, int quantity = 1)
        {
            try
            {
                log.Info($"Buy action: ProductID={productId}, Email={customerEmail}, Quantity={quantity}");

                var product = db.Products.Find(productId);
                if (product == null)
                {
                    log.Warn($"Product not found for purchase, id: {productId}");
                    return HttpNotFound();
                }

                // Verifica disponibilità
                if (product.UnitsInStock < quantity)
                {
                    ViewBag.Error = "Quantità non disponibile in magazzino.";
                    return View("Details", product);
                }

                // Cerca o crea cliente
                var customer = db.Customers.FirstOrDefault(c => c.Email == customerEmail);
                if (customer == null)
                {
                    customer = new Customer
                    {
                        Email = customerEmail,
                        FirstName = "Guest",
                        LastName = "Customer",
                        IsActive = true,
                        CreatedDate = DateTime.Now,
                        ModifiedDate = DateTime.Now
                    };
                    db.Customers.Add(customer);
                    db.SaveChanges();
                    log.Info($"New customer created: {customerEmail}");
                }

                // Crea ordine
                var order = new Order
                {
                    CustomerID = customer.CustomerID,
                    OrderDate = DateTime.Now,
                    TotalAmount = product.UnitPrice * quantity,
                    OrderStatus = "Completed",
                    PaymentStatus = "Paid",
                    CreatedDate = DateTime.Now,
                    ModifiedDate = DateTime.Now
                };
                db.Orders.Add(order);
                db.SaveChanges();

                // Crea dettaglio ordine
                var orderDetail = new OrderDetail
                {
                    OrderID = order.OrderID,
                    ProductID = product.ProductID,
                    Quantity = quantity,
                    UnitPrice = product.UnitPrice,
                    Discount = 0,
                    CreatedDate = DateTime.Now
                };
                db.OrderDetails.Add(orderDetail);

                // Aggiorna inventario
                product.UnitsInStock -= quantity;
                product.ModifiedDate = DateTime.Now;

                db.SaveChanges();

                log.Info($"Order created successfully: OrderID={order.OrderID}");

                // Invia email di conferma (salva in K:\mountfs come .eml)
                SendOrderConfirmationEmail(customer, order, product, quantity);

                ViewBag.OrderID = order.OrderID;
                ViewBag.CustomerEmail = customer.Email;
                ViewBag.ProductName = product.ProductName;
                ViewBag.Quantity = quantity;
                ViewBag.TotalAmount = order.TotalAmount;

                return View("PurchaseConfirmation");
            }
            catch (Exception ex)
            {
                log.Error($"Error during purchase: ProductID={productId}", ex);
                ViewBag.Error = "Si è verificato un errore durante l'acquisto. Riprova più tardi.";
                return View("Error");
            }
        }

        private void SendOrderConfirmationEmail(Customer customer, Order order, Product product, int quantity)
        {
            try
            {
                MailMessage mail = new MailMessage();
                mail.From = new MailAddress("noreply@devshop.com");
                mail.To.Add(new MailAddress(customer.Email));
                mail.Subject = $"Order Confirmation - Order #{order.OrderID}";
                mail.Body = $@"
Dear {customer.FirstName} {customer.LastName},

Thank you for your order!

Order Details:
- Order ID: {order.OrderID}
- Product: {product.ProductName}
- Quantity: {quantity}
- Total Amount: ${order.TotalAmount:F2}
- Order Date: {order.OrderDate:yyyy-MM-dd HH:mm}

Your order has been processed successfully.

Best regards,
devShop Team
                ";

                SmtpClient smtp = new SmtpClient();
                smtp.Send(mail);

                log.Info($"Order confirmation email sent to {customer.Email}");
            }
            catch (Exception ex)
            {
                log.Error($"Error sending confirmation email to {customer.Email}", ex);
                // Non bloccare l'acquisto se l'email fallisce
            }
        }

        protected override void Dispose(bool disposing)
        {
            if (disposing)
            {
                db.Dispose();
            }
            base.Dispose(disposing);
        }
    }
}
