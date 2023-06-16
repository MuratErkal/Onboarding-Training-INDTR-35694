export default function generateData({ data }) {
    const result = [];
    const products = [];
    for (i = 0; i < data.length; i++) {
        data[i].OrderItems.forEach((item) => {
            products.push(item);
        });
    }
}