using System;
using System.Configuration;
using System.Data.Entity;
using Microsoft.Win32;
using log4net;

namespace devShop.Models
{
    public class DevShopContext : DbContext
    {
        private static readonly ILog log = LogManager.GetLogger(typeof(DevShopContext));

        public DevShopContext() : base(GetConnectionString())
        {
            // Disabilita inizializzatori per evitare migrazioni automatiche
            Database.SetInitializer<DevShopContext>(null);
        }

        public DbSet<Category> Categories { get; set; }
        public DbSet<Product> Products { get; set; }
        public DbSet<Customer> Customers { get; set; }
        public DbSet<Order> Orders { get; set; }
        public DbSet<OrderDetail> OrderDetails { get; set; }

        protected override void OnModelCreating(DbModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // Configurazioni aggiuntive se necessarie
            modelBuilder.Entity<Product>()
                .Property(p => p.UnitPrice)
                .HasPrecision(18, 2);

            modelBuilder.Entity<Order>()
                .Property(o => o.TotalAmount)
                .HasPrecision(18, 2);

            modelBuilder.Entity<OrderDetail>()
                .Property(od => od.UnitPrice)
                .HasPrecision(18, 2);

            modelBuilder.Entity<OrderDetail>()
                .Property(od => od.Discount)
                .HasPrecision(5, 2);

            modelBuilder.Entity<OrderDetail>()
                .Property(od => od.LineTotal)
                .HasPrecision(18, 2);
        }

        /// <summary>
        /// Legge la connection string dal Registry di Windows
        /// come configurato nel lab LAB501
        /// Registry path: HKLM\Software\Devshop\DBConnection\ConnectionString
        /// </summary>
        private static string GetConnectionString()
        {
            try
            {
                // Tenta di leggere dal Registry
                using (RegistryKey key = Registry.LocalMachine.OpenSubKey(@"Software\Devshop\DBConnection"))
                {
                    if (key != null)
                    {
                        string connString = key.GetValue("ConnectionString") as string;
                        if (!string.IsNullOrEmpty(connString))
                        {
                            log.Info("Connection string letta dal Registry");
                            return connString;
                        }
                    }
                }

                // Fallback: leggi da Web.config
                log.Warn("Connection string non trovata nel Registry, uso fallback da Web.config");
                string fallbackConnString = ConfigurationManager.ConnectionStrings["DefaultConnection"]?.ConnectionString;
                
                if (string.IsNullOrEmpty(fallbackConnString))
                {
                    throw new ConfigurationErrorsException("Connection string non configurata né nel Registry né in Web.config");
                }

                return fallbackConnString;
            }
            catch (Exception ex)
            {
                log.Error("Errore durante la lettura della connection string", ex);
                throw;
            }
        }
    }
}
