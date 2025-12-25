using System;
using System.Linq;
using System.Web.Mvc;
using devShop.Models;
using log4net;

namespace devShop.Controllers
{
    public class HomeController : Controller
    {
        private static readonly ILog log = LogManager.GetLogger(typeof(HomeController));
        private DevShopContext db = new DevShopContext();

        // GET: Home
        public ActionResult Index()
        {
            try
            {
                log.Info("Home/Index accessed");

                // Carica prodotti in evidenza
                var featuredProducts = db.Products
                    .Where(p => p.IsActive && p.IsFeatured)
                    .OrderByDescending(p => p.CreatedDate)
                    .Take(6)
                    .ToList();

                ViewBag.FeaturedProducts = featuredProducts;

                // Carica categorie
                var categories = db.Categories
                    .Where(c => c.IsActive)
                    .OrderBy(c => c.CategoryName)
                    .ToList();

                ViewBag.Categories = categories;

                return View();
            }
            catch (Exception ex)
            {
                log.Error("Error in Home/Index", ex);
                ViewBag.Error = "Si è verificato un errore durante il caricamento della pagina.";
                return View("Error");
            }
        }

        public ActionResult About()
        {
            ViewBag.Message = "devShop - Your technology store";
            return View();
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
