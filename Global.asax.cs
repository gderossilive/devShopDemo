using System;
using System.Web;
using System.Web.Mvc;
using System.Web.Routing;
using log4net;

[assembly: log4net.Config.XmlConfigurator(Watch = true)]

namespace devShop
{
    public class MvcApplication : System.Web.HttpApplication
    {
        private static readonly ILog log = LogManager.GetLogger(typeof(MvcApplication));

        protected void Application_Start()
        {
            AreaRegistration.RegisterAllAreas();
            RouteConfig.RegisterRoutes(RouteTable.Routes);
            
            log.Info("devShop Application Started");
            log.Info($"Application Path: {Server.MapPath("~")}");
        }

        protected void Application_Error(object sender, EventArgs e)
        {
            Exception exception = Server.GetLastError();
            log.Error("Unhandled exception", exception);
        }

        protected void Application_End()
        {
            log.Info("devShop Application Stopped");
        }
    }
}
