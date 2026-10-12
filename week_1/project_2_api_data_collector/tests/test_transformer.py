
from transformer import transform_data


def test_transform_data():
    data = [
        {
            "id": 1,
            "name": "Leanne Graham",
            "email": "Sincere@April.biz",
        }
    ]

    result = transform_data(data)

    assert result == [
        {
            "id": 1,
            "name": "LEANNE GRAHAM",
            "email": "sincere@april.biz",
        }
    ]
