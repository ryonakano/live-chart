using Cairo;

namespace LiveChart {

    public errordomain ChartError
    {
        EXPORT_ERROR
    }

    public class Chart : Gtk.DrawingArea {

        public Grid grid { get; set construct; }
        public Drawable background { get; public set; default = new Background(); } 
        public Legend legend { get; public set; } 
        
        private Geometry geometry;

        private Gee.ArrayList<Serie> series = new Gee.ArrayList<Serie>();

        private Bounds bounds = new Bounds();

        public Chart(Geometry geometry = new Geometry()) {
            this.geometry = geometry;
            this.init_geometry();
            this.size_allocate.connect((allocation) => {
                this.geometry.height = allocation.height;
                this.geometry.width = allocation.width;
                this.geometry.update_yratio(bounds.upper, allocation.height);
            });

            this.bounds.upper_bound_updated.connect((value) => {
                this.geometry.update_yratio(value, this.get_allocated_height());
            });

            this.draw.connect(render);
            
            Timeout.add(100, () => {
                this.queue_draw();
                return true;
            });
        }

        public void add_serie(Serie serie) {
            this.series.add(serie);
            if(this.legend != null) this.legend.add_legend(serie);
        }

        public void add_value(Serie serie, double value) {
            serie.add({GLib.get_real_time() / 1000, value});
            bounds.update(value);
            this.queue_draw();
        }

        public void to_png(string filename) throws Error {
            var window = this.get_window();
            if (window == null) {
                throw new ChartError.EXPORT_ERROR("Chart is not realized yet");
            }
            var pixbuff = Gdk.pixbuf_get_from_window(window, 0, 0, window.get_width(), window.get_height());
            pixbuff.savev(filename, "png", {}, {});
        }

        private bool render(Gtk.Widget _, Context ctx) {
            ctx.select_font_face(Geometry.FONT_FACE, FontSlant.NORMAL, FontWeight.NORMAL);
            ctx.set_font_size(Geometry.FONT_SIZE);
            
            if (this.geometry.auto_padding) {
                this.geometry = this.geometry.recreate(ctx, grid, legend);
            }
            
            this.background.draw(bounds, ctx, geometry);
            this.grid.draw(bounds, ctx, geometry);
            if(this.legend != null) this.legend.draw(bounds, ctx, geometry);

            var boundaries = this.geometry.boundaries();
            foreach (Drawable serie in this.series) {
                ctx.rectangle(boundaries.x.min, boundaries.y.min, boundaries.x.max, boundaries.y.max);
                ctx.clip();
                serie.draw(bounds, ctx, this.geometry);
            }
            
            return true;
        }

        private void init_geometry() {
            geometry.height = this.get_allocated_height();
            geometry.width = this.get_allocated_width();
        }
    }
}