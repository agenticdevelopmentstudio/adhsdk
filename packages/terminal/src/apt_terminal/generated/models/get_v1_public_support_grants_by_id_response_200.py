from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.support_grant import SupportGrant
    from ..models.support_read import SupportRead


T = TypeVar("T", bound="GetV1PublicSupportGrantsByIdResponse200")


@_attrs_define
class GetV1PublicSupportGrantsByIdResponse200:
    """
    Attributes:
        grant (SupportGrant):
        reads (list[SupportRead]): The latest 50 reads under the grant, newest first.
        object_ (Literal['public.support.grant'] | Unset):
    """

    grant: SupportGrant
    reads: list[SupportRead]
    object_: Literal["public.support.grant"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        grant = self.grant.to_dict()

        reads = []
        for reads_item_data in self.reads:
            reads_item = reads_item_data.to_dict()
            reads.append(reads_item)

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "grant": grant,
                "reads": reads,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.support_grant import SupportGrant
        from ..models.support_read import SupportRead

        d = dict(src_dict)
        grant = SupportGrant.from_dict(d.pop("grant"))

        reads = []
        _reads = d.pop("reads")
        for reads_item_data in _reads:
            reads_item = SupportRead.from_dict(reads_item_data)

            reads.append(reads_item)

        object_ = cast(Literal["public.support.grant"] | Unset, d.pop("object", UNSET))
        if object_ != "public.support.grant" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'public.support.grant', got '{object_}'")

        get_v1_public_support_grants_by_id_response_200 = cls(
            grant=grant,
            reads=reads,
            object_=object_,
        )

        get_v1_public_support_grants_by_id_response_200.additional_properties = d
        return get_v1_public_support_grants_by_id_response_200

    @property
    def additional_keys(self) -> list[str]:
        return list(self.additional_properties.keys())

    def __getitem__(self, key: str) -> Any:
        return self.additional_properties[key]

    def __setitem__(self, key: str, value: Any) -> None:
        self.additional_properties[key] = value

    def __delitem__(self, key: str) -> None:
        del self.additional_properties[key]

    def __contains__(self, key: str) -> bool:
        return key in self.additional_properties
